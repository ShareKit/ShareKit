//
// LFHTTPRequest.h
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

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
    #import <CoreFoundation/CoreFoundation.h>
    #import <CFNetwork/CFNetwork.h>
    #import <CFNetwork/CFProxySupport.h>
#endif

extern NSString *const LFHTTPRequestConnectionError;
extern NSString *const LFHTTPRequestTimeoutError;
extern const NSTimeInterval LFHTTPRequestDefaultTimeoutInterval;
extern NSString *const LFHTTPRequestWWWFormURLEncodedContentType;
extern NSString *const LFHTTPRequestGETMethod;
extern NSString *const LFHTTPRequestHEADMethod;
extern NSString *const LFHTTPRequestPOSTMethod;

@interface LFHTTPRequest : NSObject
{
    id _delegate;

    NSTimeInterval _timeoutInterval;
    NSString *_userAgent;
    NSString *_contentType;

    NSDictionary *_requestHeader;

    NSMutableData *_receivedData;
    NSString *_receivedContentType;

    CFReadStreamRef _readStream;
    NSTimer *_receivedDataTracker;
    NSTimeInterval _lastReceivedDataUpdateTime;

    NSTimer *_requestMessageBodyTracker;
    NSTimeInterval _lastSentDataUpdateTime;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
    NSUInteger _requestMessageBodySize;
    NSUInteger _expectedDataLength;
    NSUInteger _lastReceivedBytes;
    NSUInteger _lastSentBytes;
#else
    unsigned int _requestMessageBodySize;
    unsigned int _expectedDataLength;
    unsigned int _lastReceivedBytes;
    unsigned int _lastSentBytes;
#endif

    void *_readBuffer;
    size_t _readBufferSize;

    id _sessionInfo;

    BOOL _shouldWaitUntilDone;
	NSMessagePort *_synchronousMessagePort;
}

- (id)init;
- (BOOL)isRunning;
- (void)cancel;
- (void)cancelWithoutDelegateMessage;

- (BOOL)shouldWaitUntilDone;
- (void)setShouldWaitUntilDone:(BOOL)waitUntilDone;

- (BOOL)performMethod:(NSString *)methodName onURL:(NSURL *)url withData:(NSData *)data;

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
- (BOOL)performMethod:(NSString *)methodName onURL:(NSURL *)url withInputStream:(NSInputStream *)inputStream knownContentSize:(NSUInteger)byteStreamSize;
#else
- (BOOL)performMethod:(NSString *)methodName onURL:(NSURL *)url withInputStream:(NSInputStream *)inputStream knownContentSize:(unsigned int)byteStreamSize;
#endif

- (NSData *)getReceivedDataAndDetachFromRequest;

- (NSDictionary *)requestHeader;
- (void)setRequestHeader:(NSDictionary *)requestHeader;
- (NSTimeInterval)timeoutInterval;
- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval;
- (NSString *)userAgent;
- (void)setUserAgent:(NSString *)userAgent;
- (NSString *)contentType;
- (void)setContentType:(NSString *)contentType;
- (NSData *)receivedData;
- (NSString *)receivedContentType;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
- (NSUInteger)expectedDataLength;
#else
- (unsigned int)expectedDataLength;
#endif
- (id)delegate;
- (void)setDelegate:(id)delegate;

- (void)setSessionInfo:(id)aSessionInfo;
- (id)sessionInfo;

#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_4
@property (copy) NSDictionary *requestHeader;
@property (assign) NSTimeInterval timeoutInterval;
@property (copy) NSString *userAgent;
@property (copy) NSString *contentType;
@property (readonly) NSData *receivedData;
@property (readonly) NSUInteger expectedDataLength;
@property (assign) id delegate;
@property (retain) id sessionInfo;
@property (assign) BOOL shouldWaitUntilDone;
@property (readonly) BOOL isRunning;
#endif
@end

@interface NSObject (LFHTTPRequestDelegate)
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
- (void)httpRequest:(LFHTTPRequest *)request didReceiveStatusCode:(NSUInteger)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header;
- (void)httpRequestDidComplete:(LFHTTPRequest *)request;
- (void)httpRequestDidCancel:(LFHTTPRequest *)request;
- (void)httpRequest:(LFHTTPRequest *)request didFailWithError:(NSString *)error;
- (void)httpRequest:(LFHTTPRequest *)request receivedBytes:(NSUInteger)bytesReceived expectedTotal:(NSUInteger)total;
- (void)httpRequest:(LFHTTPRequest *)request sentBytes:(NSUInteger)bytesSent total:(NSUInteger)total;

// note if you implemented this, the data is never written to the receivedData of the HTTP request instance
- (void)httpRequest:(LFHTTPRequest *)request writeReceivedBytes:(void *)bytes size:(NSUInteger)blockSize expectedTotal:(NSUInteger)total;
#else
- (void)httpRequest:(LFHTTPRequest *)request didReceiveStatusCode:(unsigned int)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header;
- (void)httpRequestDidComplete:(LFHTTPRequest *)request;
- (void)httpRequestDidCancel:(LFHTTPRequest *)request;
- (void)httpRequest:(LFHTTPRequest *)request didFailWithError:(NSString *)error;
- (void)httpRequest:(LFHTTPRequest *)request receivedBytes:(unsigned int)bytesReceived expectedTotal:(unsigned int)total;
- (void)httpRequest:(LFHTTPRequest *)request sentBytes:(unsigned int)bytesSent total:(unsigned int)total;
- (void)httpRequest:(LFHTTPRequest *)request writeReceivedBytes:(void *)bytes size:(unsigned int)blockSize expectedTotal:(unsigned int)total;
#endif
@end