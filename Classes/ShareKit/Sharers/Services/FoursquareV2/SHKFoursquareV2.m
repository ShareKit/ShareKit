//
//  SHKFoursquareV2.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/26/11.
//  Sponsored by Twoppy
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

#import "SHKFoursquareV2.h"
#import "SHKFoursquareV2OAuthView.h"
#import "SHKConfiguration.h"

#import "NSString+URLEncoding.h"

#import "JSON.h"

static NSString *authorizeURL = @"https://foursquare.com/oauth2/authenticate";
static NSString *accessTokenKey = @"accessToken";

@interface SHKFoursquareV2 ()

- (void)storeAccessToken;
- (BOOL)restoreAccessToken;
+ (void)deleteStoredAccessToken;

@end

@implementation SHKFoursquareV2

@synthesize clientId = _clientId;
@synthesize authorizeCallbackURL = _authorizeCallbackURL;
@synthesize accessToken = _accessToken;

- (void)dealloc
{
    self.clientId = nil;
    self.authorizeCallbackURL = nil;
    self.accessToken = nil;
    
    [super dealloc];
}

- (id)init
{
	if (self = [super init])
	{	
		// OAUTH2		
		self.clientId = SHKCONFIG(foursquareV2ClientId);		
		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(foursquareV2RedirectURI)];
	}	
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Foursquare";
}

+ (BOOL)canShareURL
{
	return NO;
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareImage
{
	return NO;
}

+ (BOOL)canShareOffline
{
	return NO;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return NO;
}


#pragma mark -
#pragma mark Authorize 

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&response_type=token&redirect_uri=%@", authorizeURL, self.clientId, [self.authorizeCallbackURL.absoluteString URLEncodedString]]];
	
	SHKFoursquareV2OAuthView *auth = [[SHKFoursquareV2OAuthView alloc] initWithURL:url delegate:self];
	[[SHK currentHelper] showViewController:auth];	
	[auth release];
}


- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error
{
    if (success) {
        self.accessToken = [queryParams objectForKey:@"access_token"];
        [self storeAccessToken];
    }
    else
    {
        [[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Access Error")
                                     message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
                                    delegate:nil
                           cancelButtonTitle:SHKLocalizedString(@"Close")
                           otherButtonTitles:nil] autorelease] show];
    }
    [self authDidFinish:success];
}

- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView
{
    [self authDidFinish:NO];
}

- (void)storeAccessToken
{	
	[SHK setAuthValue:self.accessToken
               forKey:accessTokenKey
            forSharer:[self sharerId]];
}

- (BOOL)restoreAccessToken
{
	if (self.accessToken != nil)
		return YES;
    
	self.accessToken = [SHK getAuthValueForKey:accessTokenKey
                                  forSharer:[self sharerId]];
	
	return self.accessToken != nil;
}

+ (void)deleteStoredAccessToken
{
	NSString *sharerId = [self sharerId];
	
	[SHK removeAuthValueForKey:accessTokenKey forSharer:sharerId];
}

+ (void)logout
{
	[self deleteStoredAccessToken];
	
	// Clear cookies 
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [storage cookiesForURL:[NSURL URLWithString:authorizeURL]];
    for (NSHTTPCookie *each in cookies) 
    {
        [storage deleteCookie:each];
    }
}

@end
