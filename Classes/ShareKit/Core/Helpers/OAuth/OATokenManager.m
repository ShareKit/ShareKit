//
//  OATokenManager.m
//  OAuthConsumer
//
//  Created by Alberto García Hierro on 01/09/08.
//  Copyright 2008 Alberto García Hierro. All rights reserved.
//	bynotes.com

#import "OAConsumer.h"
#import "OAToken.h"
#import "OAProblem.h"
#import "OACall.h"
#import "OATokenManager.h"

@interface OATokenManager (Private)

- (void)callProblem:(OACall *)call problem:(OAProblem *)problem;
- (void)callError:(OACall *)call error:(NSError *)error;
- (void)callFinished:(OACall *)call body:(NSString *)body;

- (void)dispatch;
- (void)performCall:(OACall *)aCall;

- (void)requestToken;
- (void)requestTokenReceived;
- (void)exchangeToken;
- (void)renewToken;
- (void)accessTokenReceived;
- (void)setAccessToken:(OAToken *)token;
- (void)deleteSavedRequestToken;

- (OACall *)queue;
- (void)enqueue:(OACall *)call selector:(SEL)selector;
- (void)dequeue:(OACall *)call;
- (SEL)getSelector:(OACall *)call;

@end

@implementation OATokenManager

- (id)init {
	return [self initWithConsumer:nil
							token:nil
						oauthBase:nil
							realm:nil
						 callback:nil
						 delegate:nil];
}

- (id)initWithConsumer:(OAConsumer *)aConsumer token:(OAToken *)aToken oauthBase:(const NSString *)base
				 realm:(const NSString *)aRealm callback:(const NSString *)aCallback
			  delegate:(NSObject <OATokenManagerDelegate> *)aDelegate {

	if ((self = [super init])) {
		consumer = [aConsumer retain];
		acToken = nil;
		reqToken = nil;
		initialToken = [aToken retain];
		authorizedTokenKey = nil;
		oauthBase = [base copy];
		realm = [aRealm copy];
		callback = [aCallback copy];
		delegate = aDelegate;
		calls = [[NSMutableArray alloc] init];
		selectors = [[NSMutableArray alloc] init];
		delegates = [[NSMutableDictionary alloc] init];
		isDispatching = NO;
	}

	return self;
}

- (void)dealloc {
	[consumer release];
	[acToken release];
	[reqToken release];
	[initialToken release];
	[authorizedTokenKey release];
	[oauthBase release];
	[realm release];
	[callback release];
	[calls release];
	[selectors release];
	[delegates release];
	[super dealloc];
}

// The application got a new authorized
// request token and is notifying us
- (void)authorizedToken:(NSString *)aKey
{
	if (reqToken && [aKey isEqualToString:reqToken.key]) {
		[self exchangeToken];
	} else {
		[authorizedTokenKey release];
		authorizedTokenKey = [aKey retain];
	}
}


// Private functions

// Deal with problems and errors in calls

- (void)call:(OACall *)call failedWithProblem:(OAProblem *)problem
{
	/* Always clear the saved request token, just in case */
	[self deleteSavedRequestToken];
	
	if ([problem isEqualToProblem:[OAProblem TokenExpired]]) {
		/* renewToken checks if it's renewable */
		[self renewToken];
	} else if ([problem isEqualToProblem:[OAProblem TokenNotRenewable]] || 
			   [problem isEqualToProblem:[OAProblem TokenRejected]]) {
		/* This token may have been revoked by the user, get a new one
		 after removing the stored requestToken, since the problem may be in
		 it */
		[self setAccessToken:nil];
		[self requestToken];
	} else if ([problem isEqualToProblem:[OAProblem NonceUsed]]) {
		/* Just repeat this request */
		[self performCall:call];
	} else {
		/* Non-recoverable error, tell the delegate and dequeue the call
		 if appropiate */
		if([delegate tokenManager:self failedCall:call withProblem:problem]) {
			[self dequeue:call];
		}
		@synchronized(self) {
			isDispatching = NO;
		}
	}
}

- (void)call:(OACall *)call failedWithError:(NSError *)error
{
	if([delegate tokenManager:self failedCall:call withError:error]) {
		[self dequeue:call];
	}
	@synchronized(self) {
		isDispatching = NO;
	}
}

// When a call finish, notify the delegate
- (void)callFinished:(OACall *)call body:(NSString *)body
{
	SEL selector = [self getSelector:call];
	id deleg = [delegates objectForKey:[NSString stringWithFormat:@"%p", call]];
	if (deleg) {
		[deleg performSelector:selector withObject:body];
		[delegates removeObjectForKey:call];
	} else {
		[delegate performSelector:selector withObject:body];
	}
	@synchronized(self) {
		isDispatching = NO;
	}
	[self dequeue:call];
	[self dispatch];
}

- (OACall *)queue {
	id obj = nil;
	@synchronized(calls) {
		if ([calls count]) {
			obj = [calls objectAtIndex:0];
		}
	}
	return obj;
}

- (void)enqueue:(OACall *)call selector:(SEL)selector {
	NSUInteger idx = [calls indexOfObject:call];
	if (idx == NSNotFound) {
		@synchronized(calls) {
			[calls addObject:call];
			[call release];
			[selectors addObject:NSStringFromSelector(selector)];
		}
	}
}

- (void)dequeue:(OACall *)call {
	NSUInteger idx = [calls indexOfObject:call];
	if (idx != NSNotFound) {
		@synchronized(calls) {
			[calls removeObjectAtIndex:idx];
			[selectors removeObjectAtIndex:idx];
		}
	}
}

- (SEL)getSelector:(OACall *)call
{
	NSUInteger idx = [calls indexOfObject:call];
	if (idx != NSNotFound) {
		return NSSelectorFromString([selectors objectAtIndex:idx]);
	}
	return 0;
}
	
// Token management functions

// Requesting a new token

// Gets a new token and opens the default
// browser for authorizing it. The application
// is expected to call authorizedToken when it
// gets the authorized token back

- (void)requestToken
{
	/* Try to load an access token from settings */
	OAToken *atoken = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:oauthBase prefix:[@"access:" stringByAppendingString:realm]] autorelease];
	if (atoken && [atoken isValid]) {
		[self setAccessToken:atoken];
		return;
	}
	/* Try to load a stored requestToken from
	 settings (useful for iPhone) */
	OAToken *token = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:oauthBase prefix:[@"request:" stringByAppendingString:realm]] autorelease];
		/* iPhone specific, the manager must have got the authorized token before reaching this point */
	NSLog(@"request token in settings %@", token);
	if (token && token.key && [authorizedTokenKey isEqualToString:token.key]) {
		reqToken = [token retain];
		[self exchangeToken];
		return;
	}
	if ([delegate respondsToSelector:@selector(tokenManagerNeedsToken:)]) {
		if (![delegate tokenManagerNeedsToken:self]) {
			return;
		}
	}
	OACall *call = [[OACall alloc] initWithURL:[NSURL URLWithString:[oauthBase stringByAppendingString:@"request_token"]] method:@"POST"];
	[call perform:consumer
			token:initialToken
			realm:realm
		 delegate:self
		didFinish:@selector(requestTokenReceived:body:)];
	
}

- (void)requestTokenReceived:(OACall *)call body:(NSString *)body
{
	/* XXX: Check if token != nil */
	NSLog(@"Received request token %@", body);
	OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:body] autorelease];
	if (token) {
		[reqToken release];
		reqToken = [token retain];
	
		[reqToken storeInUserDefaultsWithServiceProviderName:oauthBase prefix:[@"request:" stringByAppendingString:realm]];
		/* Save the token in case we exit and start again
		 before the token is authorized (useful for iPhone) */
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@authorize?oauth_token=%@&oauth_callback=%@",
										   oauthBase, token.key, callback]];
		[[UIApplication sharedApplication] openURL:url];

	}
	[call release];
}

// Exchaing a request token for an access token

// Exchanges the current authorized
// request token for an access token
- (void)exchangeToken
{
	if (!reqToken) {
		[self requestToken];
		return;
	}
	NSURL *url = [NSURL URLWithString:[oauthBase stringByAppendingString:@"access_token"]];
	OACall *call = [[OACall alloc] initWithURL:url method:@"POST"];
	[call perform:consumer
			token:reqToken
			realm:realm
		 delegate:self
		didFinish:@selector(accessTokenReceived:body:)];
}

- (void)accessTokenReceived:(OACall *)call body:(NSString *)body
{
	OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:body] autorelease];
	[self setAccessToken:token];
}

- (void)renewToken {
	NSLog(@"Renewing token");
	if (!acToken || ![acToken isRenewable]) {
		[self requestToken];
		return;
	}
	acToken.forRenewal = YES;
	NSURL *url = [NSURL URLWithString:[oauthBase stringByAppendingString:@"access_token"]];
	OACall *call = [[OACall alloc] initWithURL:url method:@"POST"];
	[call perform:consumer
			token:acToken
			realm:realm
		 delegate:self
		didFinish:@selector(accessTokenReceived:body:)];	
}

- (void)setAccessToken:(OAToken *)token {
	/* Remove the stored requestToken which generated
	 this access token */
	[self deleteSavedRequestToken];
	if (token) {
		[acToken release];
		acToken = [token retain];
		[acToken storeInUserDefaultsWithServiceProviderName:oauthBase prefix:[@"access:" stringByAppendingString:realm]];
		@synchronized(self) {
			isDispatching = NO;
		}
		[self dispatch];
	} else {
		/* Clear the in-memory and saved access tokens */
		[acToken release];
		acToken = nil;
		[OAToken removeFromUserDefaultsWithServiceProviderName:oauthBase prefix:[@"access:" stringByAppendingString:realm]];
	}
}

- (void)deleteSavedRequestToken {
	[OAToken removeFromUserDefaultsWithServiceProviderName:oauthBase prefix:[@"request:" stringByAppendingString:realm]];
	[reqToken release];
	reqToken = nil;
}

- (void)performCall:(OACall *)aCall {
	NSLog(@"Performing call");
	[aCall perform:consumer
			 token:acToken
			 realm:realm
		  delegate:self
		  didFinish:@selector(callFinished:body:)];
}

- (void)dispatch {
	OACall *call = [self queue];
	if (!call) {
		return;
	}
	@synchronized(self) {
		if (isDispatching) {
			return;
		}
		isDispatching = YES;
	}
	NSLog(@"Started dispatching");
	if(acToken) {
		[self performCall:call];
	} else if(reqToken) {
		[self exchangeToken];
	} else {
		[self requestToken];
	}
}

- (void)fetchData:(NSString *)aURL method:(NSString *)aMethod parameters:(NSArray *)theParameters
			files:(NSDictionary *)theFiles finished:(SEL)didFinish delegate:(NSObject*)aDelegate {
	
	OACall *call = [[[OACall alloc] initWithURL:[NSURL URLWithString:aURL]
										method:aMethod
									parameters:theParameters
										 files:theFiles] autorelease];
	NSLog(@"Received request for: %@", aURL);
	[self enqueue:call selector:didFinish];
	if (aDelegate) {
		[delegates setObject:aDelegate forKey:[NSString stringWithFormat:@"%p", call]];
	}
	[self dispatch];
}

- (void)fetchData:(NSString *)aURL method:(NSString *)aMethod parameters:(NSArray *)theParameters
			files:(NSDictionary *)theFiles finished:(SEL)didFinish {
	
	[self fetchData:aURL method:aMethod parameters:theParameters files:theFiles
		   finished:didFinish delegate:nil];
}


- (void)fetchData:(NSString *)aURL method:(NSString *)aMethod parameters:(NSArray *)theParameters
		 finished:(SEL)didFinish {
	
	[self fetchData:aURL method:aMethod parameters:theParameters files:nil finished:didFinish];
}

- (void)fetchData:(NSString *)aURL parameters:(NSArray *)theParameters files:(NSDictionary *)theFiles
		 finished:(SEL)didFinish {

	[self fetchData:aURL method:@"POST" parameters:theParameters files:theFiles finished:didFinish];
}

- (void)fetchData:(NSString *)aURL finished:(SEL)didFinish {
	[self fetchData:aURL method:nil parameters:nil files:nil finished:didFinish];
}

	
@end
