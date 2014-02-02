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

NSString * const kSHKFoursquareUserInfo = @"kSHKFoursquareUserInfo";

#import "SHKFoursquareV2.h"

#import "SharersCommonHeaders.h"
#import "SHKFoursquareV2OAuthView.h"
#import "SHKFoursquareV2VenuesForm.h"
#import "NSString+URLEncoding.h"
#import "NSHTTPCookieStorage+DeleteForURL.h"

static NSString *authorizeURL = @"https://foursquare.com/oauth2/authenticate";
static NSString *accessTokenKey = @"accessToken";

@interface SHKFoursquareV2 ()

- (void)storeAccessToken;
- (BOOL)restoreAccessToken;
+ (void)deleteStoredAccessToken;

@end

@implementation SHKFoursquareV2


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

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"Foursquare"); }

+ (BOOL)canShare
{
    // Check if location services are enabled and for iOS 4.2 and higher test if this app is allowed to use it
    return ([CLLocationManager locationServicesEnabled] &&
            (![CLLocationManager respondsToSelector:@selector(authorizationStatus)] ||
             [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || 
             [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined));
}

+ (BOOL)canShareText { return YES; }
+ (BOOL)canGetUserInfo { return YES; }

+ (BOOL)canShareOffline { return NO; }

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Authorize 

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)authorizationFormShow
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&response_type=token&redirect_uri=%@", authorizeURL, self.clientId, [self.authorizeCallbackURL.absoluteString URLEncodedString]]];
	
	SHKFoursquareV2OAuthView *auth = [[SHKFoursquareV2OAuthView alloc] initWithURL:url delegate:self];
	[[SHK currentHelper] showViewController:auth];	
}


- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
    if (success) {
        self.accessToken = [queryParams objectForKey:@"access_token"];
        [self storeAccessToken];
        [self tryPendingAction];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Access Error")
                                     message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
                                    delegate:nil
                           cancelButtonTitle:SHKLocalizedString(@"Close")
                           otherButtonTitles:nil] show];
    }
    [self authDidFinish:success];
}

- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];	
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
    [NSHTTPCookieStorage deleteCookiesForURL:[NSURL URLWithString:authorizeURL]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFoursquareUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKFoursquareUserInfo];
    
    if (userInfo) {
        NSString *result = [[NSString alloc] initWithFormat:@"%@ %@", userInfo[@"firstName"], userInfo[@"lastName"]];
        return result;
    } else {
        return nil;
    }
}

#pragma mark -
#pragma mark UI

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
    
    if (self.item.shareType == SHKShareTypeUserInfo) return nil;
    
    NSString *label = [SHKLocalizedString(@"Check In") stringByAppendingFormat:@" %@", SHKLocalizedString(@"Message")];
    
    SHKFormFieldLargeTextSettings *messageField = [SHKFormFieldLargeTextSettings label:label
                                                                                   key:@"text"
                                                                                 start:self.item.text
                                                                                  item:self.item];
    messageField.select = YES;
    messageField.maxTextLength = 140;
    messageField.validationBlock = ^ (SHKFormFieldLargeTextSettings *formFieldSettings) {
        
        BOOL result = [formFieldSettings.valueToSave length] <= formFieldSettings.maxTextLength;
        return result;
    };

    return @[messageField];
}

- (void)show
{
	if (self.item.shareType == SHKShareTypeText)
	{
		[self showFoursquareV2VenuesForm];
	} else {
        [super show];
    }
}

- (void)showFoursquareV2VenuesForm
{
	SHKFoursquareV2VenuesForm *venuesForm = [[SHKFoursquareV2VenuesForm alloc] initWithDelegate:self];	
	
	[self pushViewController:venuesForm animated:NO];
	
	[[SHK currentHelper] showViewController:self];	
    
}

- (void)showFoursquareV2CheckInForm;
{    
    NSArray *shareFormFields = [self shareFormFieldsForType:self.item.shareType];
    if (!shareFormFields) [self tryToSend];
    
    SHKFormController *rootView = [[SHKCONFIG(SHKFormControllerSubclass) alloc] initWithStyle:UITableViewStyleGrouped
                                                                                        title:nil
                                                                             rightButtonTitle:SHKLocalizedString(@"Check In")];
    rootView.navigationItem.leftBarButtonItem = nil;
    [self setupFormController:rootView withFields:shareFormFields];
    
    [self pushViewController:rootView animated:YES];
}

- (BOOL)send
{
    if (![self validateItem]) return NO;
    
    if (self.item.shareType == SHKShareTypeUserInfo) {
        [self downloadUserInfo];
        return YES;
    }
    
    [self sendDidStart];
    
    [SHKFoursquareV2Request startRequestCheckinLocation:self.location
                                                  venue:self.venue
                                                message:self.item.text
                                            accessToken:self.accessToken
                                             completion:^ (SHKRequest *request) {
                                                 
                                                 [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
                                                 
                                                 if (request.success)
                                                 {
                                                     [self sendDidFinish];
                                                 }
                                                 else
                                                 {
                                                     SHKFoursquareV2Request *FSRequest = (SHKFoursquareV2Request *)request;
                                                     NSError *error = FSRequest.foursquareError;
                                                     [self sendDidFailWithError:error shouldRelogin:error.foursquareRelogin];
                                                 }
                                             }];
    return YES;
}

- (void)downloadUserInfo {
    
    self.quiet = YES;
    
    [SHKFoursquareV2Request startRequestProfileForUserId:@"self" accessToken:self.accessToken completion:^(SHKRequest *request) {
        
        if (request.success) {
            NSError *error;
            NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
            NSDictionary *userInfoStripped = userInfo[@"response"][@"user"];
            [[NSUserDefaults standardUserDefaults] setObject:userInfoStripped forKey:kSHKFoursquareUserInfo];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self sendDidFinish];
        } else {
            SHKLog(@"error while fetching user info from foursquare:%@", request.response);
            [self sendDidFailWithError:nil];
        }
    }];
}

@end
