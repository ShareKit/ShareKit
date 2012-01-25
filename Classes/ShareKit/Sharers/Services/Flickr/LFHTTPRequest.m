//
// LFHTTPRequest.m
//
// Copyright (c) 2007-2009 Lithoglyph Inc. (http://lithoglyph.com)
// Copyright (c) 2007-2009 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "LFHTTPRequest.h"

// these typedefs are for this compilation unit only
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
    typedef unsigned int NSUInteger;
    typedef int NSInteger;
    #define NSUIntegerMax UINT_MAX
#endif



NSString *const LFHTTPRequestConnectionError = @"HTTP request connection lost";
NSString *const LFHTTPRequestTimeoutError = @"HTTP request timeout";

const NSTimeInterval LFHTTPRequestDefaultTimeoutInterval = 10.0;
NSString *const LFHTTPRequestWWWFormURLEncodedContentType = @"application/x-www-form-urlencoded";
NSString *const LFHTTPRequestGETMethod = @"GET";
NSString *const LFHTTPRequestHEADMethod = @"HEAD";
NSString *const LFHTTPRequestPOSTMethod = @"POST";


// internal defaults
NSString *const LFHRDefaultUserAgent = nil;
const size_t LFHTTPRequestDefaultReadBufferSize = 16384;
const NSTimeInterval LFHTTPRequestDefaultTrackerFireInterval = 1.0;


void LFHRReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo);

@interface LFHTTPRequest (PrivateMethods)
- (void)cleanUp;
- (void)dealloc;
- (void)handleTimeout;
- (void)handleRequestMessageBodyTrackerTick:(NSTimer *)timer;
- (void)handleReceivedDataTrackerTick:(NSTimer *)timer;
- (void)readStreamHasBytesAvailable;
- (void)readStreamErrorOccurred;
- (void)readStreamEndEncountered;
@end

@implementation LFHTTPRequest (PrivateMethods)
- (void)cleanUp
{
    if (_readStream) {
        CFReadStreamUnscheduleFromRunLoop(_readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(_readStream);
        CFRelease(_readStream);
        _readStream = NULL;
    }

    if (_receivedDataTracker) {
        [_receivedDataTracker invalidate];
        [_receivedDataTracker release];
        _receivedDataTracker = nil;
    }

    if (_requestMessageBodyTracker) {
        [_requestMessageBodyTracker invalidate];
        [_requestMessageBodyTracker release];
        _requestMessageBodyTracker = nil;
    }

    _requestMessageBodySize = 0;
    _expectedDataLength = NSUIntegerMax;

    _lastReceivedDataUpdateTime = 0.0;
    _lastReceivedBytes = 0;

    _lastSentDataUpdateTime = 0.0;
    _lastSentBytes = 0;

}
- (void)dealloc
{
    [self cleanUp];
    [_userAgent release];
    [_contentType release];
    [_requestHeader release];
    [_receivedData release];
    [_receivedContentType release];

    [_sessionInfo release];
    _sessionInfo = nil;

    free(_readBuffer);
    [super dealloc];
}

- (void)finalize
{
    [self cleanUp];
    if (_readBuffer) {
        free(_readBuffer);
        _readBuffer = NULL;
    }

    [super finalize];
}


- (void)_exitRunLoop
{
#if TARGET_OS_IPHONE
	[_synchronousMessagePort sendBeforeDate:[NSDate date] msgid:0 components:nil from:_synchronousMessagePort reserved:0];
	
#else
	NSPortMessage *message = [[[NSPortMessage alloc] initWithSendPort:_synchronousMessagePort receivePort:_synchronousMessagePort components:nil] autorelease];
	[message setMsgid:0];
	[message sendBeforeDate:[NSDate date]];	
#endif
}

- (void)handleTimeout
{
	if (_shouldWaitUntilDone) {
		[self _exitRunLoop];
	}
	
    [self cleanUp];
    if ([_delegate respondsToSelector:@selector(httpRequest:didFailWithError:)]) {
        [_delegate httpRequest:self didFailWithError:LFHTTPRequestTimeoutError];
    }
}
- (void)handleRequestMessageBodyTrackerTick:(NSTimer *)timer
{
    if (timer != _requestMessageBodyTracker) {
        return;
    }

    // get the number of sent bytes
    CFTypeRef sentBytesObject = CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPRequestBytesWrittenCount);
    if (!sentBytesObject) {
        // or should we send an error message?
        return;
    }

    NSInteger signedSentBytes = 0;
    CFNumberGetValue(sentBytesObject, kCFNumberCFIndexType, &signedSentBytes);
    CFRelease(sentBytesObject);

    if (signedSentBytes < 0) {
        // or should we send an error message?
        return;
    }

    // interestingly, this logic also works when ALL REQUEST MESSAGE BODY IS SENT
    NSUInteger sentBytes = (NSUInteger)signedSentBytes;
    if (sentBytes > _lastSentBytes) {
        _lastSentBytes = sentBytes;
        _lastSentDataUpdateTime = [NSDate timeIntervalSinceReferenceDate];

        if ([_delegate respondsToSelector:@selector(httpRequest:sentBytes:total:)]) {
            [_delegate httpRequest:self sentBytes:_lastSentBytes total:_requestMessageBodySize];
        }

        return;
    }

    if ([NSDate timeIntervalSinceReferenceDate] - _lastSentDataUpdateTime > _timeoutInterval) {
        // remove ourselve from the runloop
        [_requestMessageBodyTracker invalidate];
        [self handleTimeout];
    }
}
- (void)handleReceivedDataTrackerTick:(NSTimer *)timer
{
    if (timer != _receivedDataTracker) {
        return;
    }

    if ([NSDate timeIntervalSinceReferenceDate] - _lastReceivedDataUpdateTime > _timeoutInterval) {
        // remove ourselves from the runloop
        [_receivedDataTracker invalidate];
        [self handleTimeout];
    }
}
- (void)readStreamHasBytesAvailable
{
    // to prevent from stray callbacks entering here
    if (![self isRunning]) {
        return;
    }

    if (!_receivedDataTracker) {
        // update one last time the total sent bytes
        if ([_delegate respondsToSelector:@selector(httpRequest:sentBytes:total:)]) {
            [_delegate httpRequest:self sentBytes:_lastSentBytes total:_lastSentBytes];
        }

        // stops _requestMessageBodyTracker
        [_requestMessageBodyTracker invalidate];
        [_requestMessageBodyTracker release];
        _requestMessageBodyTracker = nil;

        NSUInteger statusCode = 0;

        CFURLRef finalURL = CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPFinalURL);
        CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPResponseHeader);
        if (response) {
            statusCode = (NSUInteger)CFHTTPMessageGetResponseStatusCode(response);

            CFStringRef contentLengthString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Length"));
            if (contentLengthString) {

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
                _expectedDataLength = [(NSString *)contentLengthString intValue];
#else
                if ([(NSString *)contentLengthString respondsToSelector:@selector(integerValue)]) {
                    _expectedDataLength = [(NSString *)contentLengthString integerValue];
                }
                else {
                    _expectedDataLength = [(NSString *)contentLengthString intValue];
                }
#endif

                CFRelease(contentLengthString);
            }

            [_receivedContentType release];
            _receivedContentType = nil;

            CFStringRef contentTypeString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Type"));
            if (contentTypeString) {
                _receivedContentType = [(NSString *)contentTypeString copy];
                CFRelease(contentTypeString);
            }
        }

        CFReadStreamRef presentReadStream = _readStream;

        if ([_delegate respondsToSelector:@selector(httpRequest:didReceiveStatusCode:URL:responseHeader:)]) {
            [_delegate httpRequest:self didReceiveStatusCode:statusCode URL:(NSURL *)finalURL responseHeader:response];
        }

        if (finalURL) {
            CFRelease(finalURL);
        }

        if (response) {
            CFRelease(response);
        }

        // better to see if we're still running... (we might be canceled by the delegate's httpRequest:didReceiveStatusCode:URL:responseHeader: !)
        if (presentReadStream != _readStream) {
            return;
        }

		// start tracking received bytes
        _lastReceivedBytes = 0;
        _lastReceivedDataUpdateTime = [NSDate timeIntervalSinceReferenceDate];

        // now we fire _receivedDataTracker
        _receivedDataTracker = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:LFHTTPRequestDefaultTrackerFireInterval target:self selector:@selector(handleReceivedDataTrackerTick:) userInfo:nil repeats:YES];
        #if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
                // this is 10.5 only
                [[NSRunLoop currentRunLoop] addTimer:_receivedDataTracker forMode:NSRunLoopCommonModes];
        #endif

                [[NSRunLoop currentRunLoop] addTimer:_receivedDataTracker forMode:NSDefaultRunLoopMode];

                // These two are defined in the AppKit, not in the Foundation
        #if TARGET_OS_MAC && !TARGET_OS_IPHONE
                extern NSString *NSModalPanelRunLoopMode;
                extern NSString *NSEventTrackingRunLoopMode;
                [[NSRunLoop currentRunLoop] addTimer:_receivedDataTracker forMode:NSEventTrackingRunLoopMode];
                [[NSRunLoop currentRunLoop] addTimer:_receivedDataTracker forMode:NSModalPanelRunLoopMode];
        #endif
    }

    // sets a 25,600-byte block, approximately for 256 KBPS connection
    CFIndex bytesRead = CFReadStreamRead(_readStream, _readBuffer, _readBufferSize);
    if (bytesRead > 0) {
        if ([_delegate respondsToSelector:@selector(httpRequest:writeReceivedBytes:size:expectedTotal:)]) {
            [_delegate httpRequest:self writeReceivedBytes:_readBuffer size:bytesRead expectedTotal:_expectedDataLength];

            _lastReceivedBytes += bytesRead;
            _lastReceivedDataUpdateTime = [NSDate timeIntervalSinceReferenceDate];

        }
        else {
            [_receivedData appendBytes:_readBuffer length:bytesRead];
            _lastReceivedBytes = [_receivedData length];
            _lastReceivedDataUpdateTime = [NSDate timeIntervalSinceReferenceDate];

            if ([_delegate respondsToSelector:@selector(httpRequest:receivedBytes:expectedTotal:)]) {
                [_delegate httpRequest:self receivedBytes:_lastReceivedBytes expectedTotal:_expectedDataLength];
            }
        }
    }
}

- (void)readStreamEndEncountered
{
    // to prevent from stray callbacks entering here
    if (![self isRunning]) {
        return;
    }

	// if no byte read, we need to present the header at least again, because readStreamHasBytesAvailable is never called
	if (![_receivedData length] && ![_delegate respondsToSelector:@selector(httpRequest:writeReceivedBytes:size:expectedTotal:)]) {
		if ([_delegate respondsToSelector:@selector(httpRequest:sentBytes:total:)]) {
			[_delegate httpRequest:self sentBytes:_lastSentBytes total:_lastSentBytes];
		}

		// stops _requestMessageBodyTracker
		[_requestMessageBodyTracker invalidate];
		[_requestMessageBodyTracker release];
		_requestMessageBodyTracker = nil;

		NSUInteger statusCode = 0;

		CFURLRef finalURL = CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPFinalURL);
		CFHTTPMessageRef response = (CFHTTPMessageRef)CFReadStreamCopyProperty(_readStream, kCFStreamPropertyHTTPResponseHeader);
		if (response) {
			statusCode = (NSUInteger)CFHTTPMessageGetResponseStatusCode(response);

			CFStringRef contentLengthString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Length"));
			if (contentLengthString) {

	#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
				_expectedDataLength = [(NSString *)contentLengthString intValue];
	#else
				if ([(NSString *)contentLengthString respondsToSelector:@selector(integerValue)]) {
					_expectedDataLength = [(NSString *)contentLengthString integerValue];
				}
				else {
					_expectedDataLength = [(NSString *)contentLengthString intValue];
				}
	#endif

				CFRelease(contentLengthString);
			}

			[_receivedContentType release];
			_receivedContentType = nil;

			CFStringRef contentTypeString = CFHTTPMessageCopyHeaderFieldValue(response, CFSTR("Content-Type"));
			if (contentTypeString) {
				_receivedContentType = [(NSString *)contentTypeString copy];
				CFRelease(contentTypeString);
			}
		}

		if ([_delegate respondsToSelector:@selector(httpRequest:didReceiveStatusCode:URL:responseHeader:)]) {
			[_delegate httpRequest:self didReceiveStatusCode:statusCode URL:(NSURL *)finalURL responseHeader:response];
		}

		if (finalURL) {
			CFRelease(finalURL);
		}

		if (response) {
			CFRelease(response);
		}
	}


    [self cleanUp];

    if ([_delegate respondsToSelector:@selector(httpRequestDidComplete:)]) {
        [_delegate httpRequestDidComplete:self];
    }
}
- (void)readStreamErrorOccurred
{
    // to prevent from stray callbacks entering here
    if (![self isRunning]) {
        return;
    }

    [self cleanUp];

    if ([_delegate respondsToSelector:@selector(httpRequest:didFailWithError:)]) {
        [_delegate httpRequest:self didFailWithError:LFHTTPRequestConnectionError];
    }
}
@end

@implementation LFHTTPRequest
- (id)init
{
    if ((self = [super init])) {
        _timeoutInterval = LFHTTPRequestDefaultTimeoutInterval;

        _receivedData = [NSMutableData new];
        _expectedDataLength = NSUIntegerMax;
        _readBufferSize = LFHTTPRequestDefaultReadBufferSize;
        _readBuffer = calloc(1, _readBufferSize);
        NSAssert(_readBuffer, @"Must have enough memory for _readBuffer");
    }

    return self;
}

- (BOOL)isRunning
{
    return !!_readStream;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
- (BOOL)_performMethod:(NSString *)methodName onURL:(NSURL *)url withData:(NSData *)data orWithInputStream:(NSInputStream *)inputStream knownContentSize:(NSUInteger)byteStreamSize
#else
- (BOOL)_performMethod:(NSString *)methodName onURL:(NSURL *)url withData:(NSData *)data orWithInputStream:(NSInputStream *)inputStream knownContentSize:(unsigned int)byteStreamSize
#endif
{
	if (!url) {
		return NO;
	}

    if (_readStream) {
        return NO;
    }

    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(NULL, (CFStringRef)methodName, (CFURLRef)url, kCFHTTPVersion1_1);
    if (!request) {
        return NO;
    }

    // combine the header
    NSMutableDictionary *headerDictionary = [NSMutableDictionary dictionary];
    if (_userAgent) {
        [headerDictionary setObject:_userAgent forKey:@"User-Agent"];
    }

    if (_contentType) {
        [headerDictionary setObject:_contentType forKey:@"Content-Type"];
    }

    if (inputStream) {
        if (byteStreamSize && byteStreamSize != NSUIntegerMax) {
            [headerDictionary setObject:[NSString stringWithFormat:@"%lu", byteStreamSize] forKey:@"Content-Length"];
            _requestMessageBodySize = byteStreamSize;
        }
        else {
            _requestMessageBodySize = NSUIntegerMax;
        }
    }
    else {
        if ([data length]) {
            [headerDictionary setObject:[NSString stringWithFormat:@"%lu", [data length]] forKey:@"Content-Length"];
        }
        _requestMessageBodySize = [data length];
    }

    if (_requestHeader) {
        [headerDictionary addEntriesFromDictionary:_requestHeader];
    }

    NSEnumerator *dictEnumerator = [headerDictionary keyEnumerator];
    id key;
    while ((key = [dictEnumerator nextObject])) {
        CFHTTPMessageSetHeaderFieldValue(request, (CFStringRef)[key description], (CFStringRef)[headerDictionary objectForKey:key]);
    }

    if (!inputStream && data) {
        CFHTTPMessageSetBody(request, (CFDataRef)data);
    }

    CFReadStreamRef tmpReadStream;

    if (inputStream) {
        tmpReadStream = CFReadStreamCreateForStreamedHTTPRequest(NULL, request, (CFReadStreamRef)inputStream);
    }
    else {
        tmpReadStream = CFReadStreamCreateForHTTPRequest(NULL, request);
    }

    CFRelease(request);
    if (!tmpReadStream) {
        return NO;
    }

    CFReadStreamSetProperty(tmpReadStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);

    // apply current proxy settings
	#if !TARGET_OS_IPHONE
		CFDictionaryRef proxyDict = SCDynamicStoreCopyProxies(NULL); // kCFNetworkProxiesHTTPProxy
	#else
		CFDictionaryRef proxyDict = CFNetworkCopySystemProxySettings();
	#endif	

    if (proxyDict) {
        CFReadStreamSetProperty(tmpReadStream, kCFStreamPropertyHTTPProxy, proxyDict);
        CFRelease(proxyDict);
    }

    CFStreamClientContext streamContext;
    streamContext.version = 0;
    streamContext.info = self;
    streamContext.retain = 0;
    streamContext.release = 0;
    streamContext.copyDescription = 0;

    CFOptionFlags eventFlags = kCFStreamEventHasBytesAvailable | kCFStreamEventEndEncountered | kCFStreamEventErrorOccurred;

    // open the stream with callback function
    if (!CFReadStreamSetClient(tmpReadStream, eventFlags, LFHRReadStreamClientCallBack, &streamContext))
    {
        CFRelease(tmpReadStream);
        return NO;
    }

    // detach and release the previous data buffer
    if ([_receivedData length]) {
        NSMutableData *tmp = _receivedData;
        _receivedData = [NSMutableData new];
        [tmp release];
    }

    CFReadStreamScheduleWithRunLoop(tmpReadStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);

    // we need to assign this in advance, because the callback might be called anytime between this and the next statement
    _readStream = tmpReadStream;

    _expectedDataLength = NSUIntegerMax;

    // open the stream
    Boolean result = CFReadStreamOpen(tmpReadStream);
    if (!result) {
        CFReadStreamUnscheduleFromRunLoop(tmpReadStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFRelease(tmpReadStream);
        _readStream = NULL;
        return NO;
    }


	_lastSentBytes = 0;
    _lastSentDataUpdateTime = [NSDate timeIntervalSinceReferenceDate];

    // we create _requestMessageBodyTracker (timer for tracking sent data) first
    _requestMessageBodyTracker = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:LFHTTPRequestDefaultTrackerFireInterval target:self selector:@selector(handleRequestMessageBodyTrackerTick:) userInfo:nil repeats:YES];

#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
    // this is 10.5 only
    [[NSRunLoop currentRunLoop] addTimer:_requestMessageBodyTracker forMode:NSRunLoopCommonModes];
#endif

    [[NSRunLoop currentRunLoop] addTimer:_requestMessageBodyTracker forMode:NSDefaultRunLoopMode];

    // These two are defined in the AppKit, not in the Foundation
    #if TARGET_OS_MAC && !TARGET_OS_IPHONE
    extern NSString *NSModalPanelRunLoopMode;
    extern NSString *NSEventTrackingRunLoopMode;
    [[NSRunLoop currentRunLoop] addTimer:_requestMessageBodyTracker forMode:NSEventTrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:_requestMessageBodyTracker forMode:NSModalPanelRunLoopMode];
    #endif

    if (_shouldWaitUntilDone) {
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        NSString *currentMode = [currentRunLoop currentMode];
		
		if (![currentMode length]) {
			currentMode = NSDefaultRunLoopMode;
		}
		
		BOOL isReentrant = (_synchronousMessagePort != nil);
		
		if (!isReentrant) {
			_synchronousMessagePort = (NSMessagePort *)[[NSPort port] retain];
			[currentRunLoop addPort:_synchronousMessagePort forMode:currentMode];
		}
		
        while ([self isRunning]) {
            [currentRunLoop runMode:currentMode beforeDate:[NSDate distantFuture]];
        }
		
		if (!isReentrant) {
			[currentRunLoop removePort:_synchronousMessagePort forMode:currentMode];
			[_synchronousMessagePort release];
			_synchronousMessagePort = nil;
		}
		else {
			// sends another message to exit the runloop
			[self _exitRunLoop];
		}
    }

    return YES;
}

- (BOOL)performMethod:(NSString *)methodName onURL:(NSURL *)url withData:(NSData *)data
{
    return [self _performMethod:methodName onURL:url withData:data orWithInputStream:nil knownContentSize:0];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
- (BOOL)performMethod:(NSString *)methodName onURL:(NSURL *)url withInputStream:(NSInputStream *)inputStream knownContentSize:(NSUInteger)byteStreamSize
#else
- (BOOL)performMethod:(NSString *)methodName onURL:(NSURL *)url withInputStream:(NSInputStream *)inputStream knownContentSize:(unsigned int)byteStreamSize
#endif
{
    return [self _performMethod:methodName onURL:url withData:nil orWithInputStream:inputStream knownContentSize:byteStreamSize];
}

- (void)cancel
{
    [self cancelWithoutDelegateMessage];
    if ([_delegate respondsToSelector:@selector(httpRequestDidCancel:)]) {
        [_delegate httpRequestDidCancel:self];
    }
}
- (void)cancelWithoutDelegateMessage
{
    [self cleanUp];
}
- (NSData *)getReceivedDataAndDetachFromRequest
{
    NSData *returnedData = [_receivedData autorelease];
    _receivedData = [NSMutableData new];

    [_receivedContentType release];
    _receivedContentType = nil;

    return returnedData;
}
- (NSDictionary *)requestHeader
{
    return [[_requestHeader copy] autorelease];
}
- (void)setRequestHeader:(NSDictionary *)requestHeader
{
    if (![_requestHeader isEqualToDictionary:requestHeader]) {
        NSDictionary *tmp = _requestHeader;
        _requestHeader = [requestHeader copy];
        [tmp release];
    }
}
- (NSTimeInterval)timeoutInterval
{
    return _timeoutInterval;
}
- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    if (_timeoutInterval != timeoutInterval) {
        _timeoutInterval = timeoutInterval;
    }
}
- (NSString *)userAgent
{
    return [[_userAgent copy] autorelease];
}
- (void)setUserAgent:(NSString *)userAgent
{
    if ([_userAgent isEqualToString:userAgent]) {
        return;
    }

    NSString *tmp = _userAgent;
    _userAgent = [userAgent copy];
    [tmp release];
}
- (NSString *)contentType
{
    return [[_contentType copy] autorelease];
}
- (void)setContentType:(NSString *)contentType
{
    if ([_contentType isEqualToString:contentType]) {
        return;
    }

    NSString *tmp = _contentType;
    _contentType = [contentType copy];
    [tmp release];
}
- (NSData *)receivedData
{
    return [[_receivedData retain] autorelease];
}

- (NSString *)receivedContentType
{
	return [[_receivedContentType copy] autorelease];
}

- (NSUInteger)expectedDataLength
{
    return _expectedDataLength;
}
- (id)delegate
{
    return _delegate;
}
- (void)setDelegate:(id)delegate
{
    if (delegate != _delegate) {
        _delegate = delegate;
    }
}

- (void)setSessionInfo:(id)aSessionInfo
{
    id tmp = _sessionInfo;
    _sessionInfo = [aSessionInfo retain];
    [tmp release];
}
- (id)sessionInfo
{
    return [[_sessionInfo retain] autorelease];
}

- (size_t)readBufferSize
{
    return _readBufferSize;
}

- (void)setReadBufferSize:(size_t)newSize
{
    NSAssert(![self isRunning], @"Cannot set read buffer size while the request is running");
    NSAssert(newSize, @"Read buffer size must > 0");

    _readBufferSize = newSize;
    _readBuffer = realloc(_readBuffer, newSize);
    NSAssert(_readBuffer, @"Must have enough memory for reallocing _readBuffer");
    bzero(_readBuffer, newSize);
}

- (BOOL)shouldWaitUntilDone
{
    return _shouldWaitUntilDone;
}

- (void)setShouldWaitUntilDone:(BOOL)waitUntilDone
{
    _shouldWaitUntilDone = waitUntilDone;
}

@end

void LFHRReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo)
{
    id pool = [NSAutoreleasePool new];

    LFHTTPRequest *request = (LFHTTPRequest *)clientCallBackInfo;
    switch (eventType) {
        case kCFStreamEventHasBytesAvailable:
            [request readStreamHasBytesAvailable];
            break;
        case kCFStreamEventEndEncountered:
            [request readStreamEndEncountered];
            break;
        case kCFStreamEventErrorOccurred:
            [request readStreamErrorOccurred];
            break;
    }
    [pool drain];
}
