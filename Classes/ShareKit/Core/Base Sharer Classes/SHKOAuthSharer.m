//
//  SHKOAuthSharer.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKOAuthSharer.h"
#import "SHKOAuthView.h"
#import "NSHTTPCookieStorage+DeleteForURL.h"
#import "SharersCommonHeaders.h"

@implementation SHKOAuthSharer

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{		
	[self tokenRequest];
}


#pragma mark Request

- (void)tokenRequest
{
	[self displayActivity:SHKLocalizedString(@"Connecting...")];
	
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:self.requestURL
                                                                   consumer:self.consumer
                                                                      token:nil   // we don't have a Token yet
                                                                      realm:nil   // our service provider doesn't specify a realm
														   signatureProvider:self.signatureProvider];
																
	
	[oRequest setHTTPMethod:@"POST"];
	
	[self tokenRequestModifyRequest:oRequest];
	
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                         delegate:self
                didFinishSelector:@selector(tokenRequestTicket:didFinishWithData:)
                  didFailSelector:@selector(tokenRequestTicket:didFailWithError:)];
	[fetcher start];	
}

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Subclass to add custom paramaters and headers
}

- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (SHKDebugShowLogs) // check so we don't have to alloc the string with the data if we aren't logging
		SHKLog(@"tokenRequestTicket Response Body: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	[self hideActivityIndicator];
	
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		OAToken *aToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        self.requestToken =  aToken;
		
		[self tokenAuthorize];
	}
	
	else
		// TODO - better error handling here
		[self tokenRequestTicket:ticket didFailWithError:[SHK error:SHKLocalizedString(@"There was a problem requesting authorization from %@", [self sharerTitle])]];
}

- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self hideActivityIndicator];
	
	[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Request Error")
								 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
								delegate:nil
					   cancelButtonTitle:SHKLocalizedString(@"Close")
					   otherButtonTitles:nil] show];
}


#pragma mark Authorize 

- (void)tokenAuthorize
{	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@", [self.authorizeURL absoluteString], self.requestToken.key]];
	
	SHKOAuthView *auth = [[SHKOAuthView alloc] initWithURL:url delegate:self];
	[[SHK currentHelper] showViewController:auth];	
}

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error;
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	if (!success)
	{
		[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
									 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while authorizing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] show];
		[self authDidFinish:success];
	}	
	
	else if ([queryParams objectForKey:@"oauth_problem"])
	{
		SHKLog(@"oauth_problem reported: %@", [queryParams objectForKey:@"oauth_problem"]);

		[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
									 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while authorizing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] show];
		success = NO;
		[self authDidFinish:success];
	}

	else 
	{
		self.authorizeResponseQueryVars = queryParams;
		
		[self tokenAccess];
	}
}

- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[self authDidFinish:NO];
}


#pragma mark Access

- (void)tokenAccess
{
	[self tokenAccess:NO];
}

- (void)tokenAccess:(BOOL)refresh
{
	if (!refresh)
		[self displayActivity:SHKLocalizedString(@"Authenticating...")];
	
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:self.accessURL
                                                                   consumer:self.consumer
																	   token:(refresh ? self.accessToken : self.requestToken)
                                                                      realm:nil   // our service provider doesn't specify a realm
                                                          signatureProvider:self.signatureProvider]; // use the default method, HMAC-SHA1
	
    [oRequest setHTTPMethod:@"POST"];
	
	[self tokenAccessModifyRequest:oRequest];
	
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                         delegate:self
                didFinishSelector:@selector(tokenAccessTicket:didFinishWithData:)
                  didFailSelector:@selector(tokenAccessTicket:didFailWithError:)];
	[fetcher start];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Subclass to add custom paramaters or headers	
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (SHKDebugShowLogs) // check so we don't have to alloc the string with the data if we aren't logging
		SHKLog(@"tokenAccessTicket Response Body: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	[self hideActivityIndicator];
	
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		OAToken *aAccesToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
        self.accessToken = aAccesToken;
        
		[self storeAccessToken];
		
		[self tryPendingAction];
	}
	
	
	else
		// TODO - better error handling here
		[self tokenAccessTicket:ticket didFailWithError:[SHK error:SHKLocalizedString(@"There was a problem requesting access from %@", [self sharerTitle])]];

	[self authDidFinish:ticket.didSucceed];
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self hideActivityIndicator];
	
	[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Access Error")
								 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
								delegate:nil
					   cancelButtonTitle:SHKLocalizedString(@"Close")
					   otherButtonTitles:nil] show];
}

- (void)storeAccessToken
{	
	[SHK setAuthValue:self.accessToken.key
					 forKey:@"accessKey"
				  forSharer:[self sharerId]];
	
	[SHK setAuthValue:self.accessToken.secret
					 forKey:@"accessSecret"
			forSharer:[self sharerId]];
	
	[SHK setAuthValue:self.accessToken.sessionHandle
			   forKey:@"sessionHandle"
			forSharer:[self sharerId]];
}

+ (void)deleteStoredAccessToken
{
	NSString *sharerId = [self sharerId];
	
	[SHK removeAuthValueForKey:@"accessKey" forSharer:sharerId];
	[SHK removeAuthValueForKey:@"accessSecret" forSharer:sharerId];
	[SHK removeAuthValueForKey:@"sessionHandle" forSharer:sharerId];
}

+ (void)logout
{
	[self deleteStoredAccessToken];
	
	// Clear cookies (for OAuth, doesn't affect XAuth)
	// TODO - move the authorizeURL out of the init call (into a define) so we don't have to create an object just to get it
	SHKOAuthSharer *sharer = [[self alloc] init];
	if (sharer.authorizeURL)
	{
		[NSHTTPCookieStorage deleteCookiesForURL:sharer.authorizeURL];
    }
}

- (BOOL)restoreAccessToken
{
	self.consumer = [[OAConsumer alloc] initWithKey:self.consumerKey secret:self.secretKey];
	
	if (self.accessToken != nil)
		return YES;
		
	NSString *key = [SHK getAuthValueForKey:@"accessKey"
				  forSharer:[self sharerId]];
	
	NSString *secret = [SHK getAuthValueForKey:@"accessSecret"
									 forSharer:[self sharerId]];
	
	NSString *sessionHandle = [SHK getAuthValueForKey:@"sessionHandle"
									 forSharer:[self sharerId]];
	
	if (key != nil && secret != nil)
	{
		self.accessToken = [[OAToken alloc] initWithKey:key secret:secret];
		
		if (sessionHandle != nil)
			self.accessToken.sessionHandle = sessionHandle;
		
		return self.accessToken != nil;
	}
	
	return NO;
}


#pragma mark Expired

- (void)refreshToken
{
	self.pendingAction = SHKPendingRefreshToken;
	[self tokenAccess:YES];
}

@end
