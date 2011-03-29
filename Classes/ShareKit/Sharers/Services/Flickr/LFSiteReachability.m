//
// LFSiteReachability.m
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

#import "LFSiteReachability.h"
#import <arpa/inet.h>

static NSString *kDefaultSite = @"http://google.com";
static NSTimeInterval kDefaultTimeoutInterval = 15.0;

#define LFSRDebug(format, ...)
// #define LFSRDebug NSLog

NSString *const LFSiteReachabilityConnectionTypeWiFi = @"LFSiteReachabilityConnectionTypeWiFi";
NSString *const LFSiteReachabilityConnectionTypeWWAN = @"LFSiteReachabilityConnectionTypeWWAN";
NSString *const LFSiteReachabilityNotReachableStatus = @"LFSiteReachabilityNotReachable";

#if !TARGET_OS_IPHONE
	#define SCNetworkReachabilityFlags SCNetworkConnectionFlags
	#define kSCNetworkReachabilityFlagsConnectionRequired kSCNetworkFlagsConnectionRequired
	#define kSCNetworkReachabilityFlagsReachable kSCNetworkFlagsReachable
	#define kSCNetworkReachabilityFlagsIsWWAN 0
#endif

static void LFSiteReachabilityCallback(SCNetworkReachabilityRef inTarget, SCNetworkReachabilityFlags inFlags, void *inInfo);

@implementation LFSiteReachability
- (void)dealloc
{
	delegate = nil;

	[siteRequest setDelegate:nil];
	[self stopChecking];
	[siteRequest release];
	[siteURL release];	
	
    [super dealloc];
}

- (void)finalize
{
	[siteRequest setDelegate:nil];
	[self stopChecking];
	[super finalize];
}

- (id)init
{
	if ((self = [super init])) {
		siteRequest = [[LFHTTPRequest alloc] init];
		[siteRequest setDelegate:self];
		[siteRequest setTimeoutInterval:kDefaultTimeoutInterval];
		
		siteURL = [[NSURL URLWithString:kDefaultSite] retain];
	}
	
	return self;
}

- (void)handleTimeoutTimer:(NSTimer *)inTimer
{
	LFSRDebug(@"%s", __PRETTY_FUNCTION__);
	[inTimer invalidate];

	if (lastCheckStatus != LFSiteReachabilityNotReachableStatus) {
		lastCheckStatus = LFSiteReachabilityNotReachableStatus;
		if ([delegate respondsToSelector:@selector(reachability:siteIsNotAvailable:)]) {
			[delegate reachability:self siteIsNotAvailable:siteURL];
		}
	}		
}

- (void)stopTimeoutTimer
{
	if ([timeoutTimer isValid]) {
		[timeoutTimer invalidate];
	}
	
	[timeoutTimer release];
	timeoutTimer = nil;	
}

- (void)handleReachabilityCallbackFlags:(SCNetworkReachabilityFlags)inFlags
{
	[self stopTimeoutTimer];

	LFSRDebug(@"%s, flags: 0x%08x", __PRETTY_FUNCTION__, inFlags);

	if (inFlags & kSCNetworkReachabilityFlagsReachable) {						
		NSString *connectionType = (inFlags & kSCNetworkReachabilityFlagsIsWWAN) ? LFSiteReachabilityConnectionTypeWWAN : LFSiteReachabilityConnectionTypeWiFi;		
		
		BOOL connectionRequestNotRequired = !(inFlags & kSCNetworkReachabilityFlagsConnectionRequired);
		
		if (siteURL) {
			LFSRDebug(@"%s, connectionRequestNotRequired: %d, attempting to request from: %@", __PRETTY_FUNCTION__, connectionRequestNotRequired, siteURL);
			
			// next stage: send the request
			[siteRequest cancelWithoutDelegateMessage];
			[siteRequest setSessionInfo:connectionType];
			if ([siteRequest performMethod:LFHTTPRequestHEADMethod onURL:siteURL withData:nil]) {
				return;
			}				
		}
		else {
			if (lastCheckStatus != connectionType) {
				lastCheckStatus = connectionType;
				if (connectionRequestNotRequired && [delegate respondsToSelector:@selector(reachability:site:isAvailableOverConnectionType:)]) {
					[delegate reachability:self site:siteURL isAvailableOverConnectionType:connectionType];
					return;
				}			
			}
		}
	}
	
	// if all fails
	if (lastCheckStatus != LFSiteReachabilityNotReachableStatus) {
		lastCheckStatus = LFSiteReachabilityNotReachableStatus;
		if ([delegate respondsToSelector:@selector(reachability:siteIsNotAvailable:)]) {
			[delegate reachability:self siteIsNotAvailable:siteURL];
		}
	}
}

- (BOOL)networkConnectivityExists
{
	// 0.0.0.0
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	
	SCNetworkReachabilityRef localReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags = 0;
	
	BOOL capable = NO;
	if (SCNetworkReachabilityGetFlags(localReachability, &flags)) {
		if (flags & kSCNetworkReachabilityFlagsReachable) {
			capable = YES;
		}
	}
	
	CFRelease(localReachability);
	return capable;
}

- (void)startChecking
{
	[self stopChecking];

	// 0.0.0.0
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	
	reachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
	SCNetworkReachabilityFlags flags = 0;
	
	BOOL createTimeoutTimer = YES;
	if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
		[self handleReachabilityCallbackFlags:flags];
		createTimeoutTimer = NO;
	}
	
	SCNetworkReachabilityContext context = {0, self, NULL, NULL, NULL};
	SCNetworkReachabilitySetCallback(reachability, LFSiteReachabilityCallback, &context);
	SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
			
	if (createTimeoutTimer) {
		timeoutTimer = [[NSTimer scheduledTimerWithTimeInterval:[siteRequest timeoutInterval] target:self selector:@selector(handleTimeoutTimer:) userInfo:NULL repeats:NO] retain];
	}
}

- (void)stopChecking
{
	[siteRequest cancelWithoutDelegateMessage];
	[self stopTimeoutTimer];
	
	if (reachability) {
		SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		CFRelease(reachability);
		reachability = NULL;		
	}
	
	lastCheckStatus = nil;
}

- (BOOL)isChecking
{
	return !!reachability;
}

- (NSTimeInterval)timeoutInterval
{
	return [siteRequest timeoutInterval];
}

- (void)setTimeoutInterval:(NSTimeInterval)inInterval
{
	[siteRequest setTimeoutInterval:inInterval];
}

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4                
- (void)httpRequest:(LFHTTPRequest *)request didReceiveStatusCode:(int)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header
#else
- (void)httpRequest:(LFHTTPRequest *)request didReceiveStatusCode:(NSUInteger)statusCode URL:(NSURL *)url responseHeader:(CFHTTPMessageRef)header
#endif
{
	LFSRDebug(@"%s, code: %d, URL: %@, header: %@", __PRETTY_FUNCTION__, statusCode, url, (id)header);
}

- (void)httpRequestDidComplete:(LFHTTPRequest *)request
{
	LFSRDebug(@"%s, connection type: %@, received data: %@", __PRETTY_FUNCTION__, [request sessionInfo], [request receivedData]);
	
	if (lastCheckStatus != [request sessionInfo]) {
		lastCheckStatus = [request sessionInfo];
		if ([delegate respondsToSelector:@selector(reachability:site:isAvailableOverConnectionType:)]) {
			[delegate reachability:self site:siteURL isAvailableOverConnectionType:[request sessionInfo]];
		}	
	}
}

- (void)httpRequest:(LFHTTPRequest *)request didFailWithError:(NSString *)error
{
	LFSRDebug(@"%s, error: %@", __PRETTY_FUNCTION__, error);
	
	if (lastCheckStatus != LFSiteReachabilityNotReachableStatus) {
		lastCheckStatus = LFSiteReachabilityNotReachableStatus;
		if ([delegate respondsToSelector:@selector(reachability:siteIsNotAvailable:)]) {
			[delegate reachability:self siteIsNotAvailable:siteURL];
		}	
	}
}

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4                
- (id<LFSiteReachabilityDelegate>)delegate
{
	return delegate;
}

- (NSURL*)siteURL
{
	return [[siteURL retain] autorelease];
}

#else
@synthesize delegate;
@synthesize siteURL;
#endif
@end


void LFSiteReachabilityCallback(SCNetworkReachabilityRef inTarget, SCNetworkReachabilityFlags inFlags, void *inInfo)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	LFSRDebug(@"%s, flags: 0x%08x", __PRETTY_FUNCTION__, inFlags);

	[(LFSiteReachability *)inInfo handleReachabilityCallbackFlags:inFlags];	
	[pool drain];
}
