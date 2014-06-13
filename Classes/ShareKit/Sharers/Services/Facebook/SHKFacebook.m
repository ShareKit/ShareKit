//
//  SHKFacebook.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.
//	3.0 SDK rewrite - Steven Troppoli 9/25/2012

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

#import "SHKFacebook.h"

#import "SHKFacebookCommon.h"
#import "SharersCommonHeaders.h"

#import "NSMutableDictionary+NSNullsToEmptyStrings.h"
#import "NSHTTPCookieStorage+DeleteForURL.h"

#import <FacebookSDK/FacebookSDK.h>

@implementation SHKFacebook

#pragma mark - 
#pragma mark Initialization

+ (void)setupFacebookSDK {
    
    [FBSettings setDefaultAppID:SHKCONFIG(facebookAppId)];
    [FBSettings setDefaultUrlSchemeSuffix:SHKCONFIG(facebookLocalAppId)];
}
- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        [SHKFacebook setupFacebookSDK];
    }
    return self;
}

#pragma mark -
#pragma mark App lifecycle

+ (void)handleDidBecomeActive
{
    [SHKFacebook setupFacebookSDK];
    [FBAppEvents activateApp];
    
	// We need to properly handle activation of the application with regards to SSO
	//  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
	[FBSession.activeSession handleDidBecomeActive];
}

+ (BOOL)handleOpenURL:(NSURL*)url sourceApplication:(NSString *)sourceApplication
{
	[SHKFacebook setupFacebookSDK];
    
    BOOL result = [FBAppCall handleOpenURL:url
                         sourceApplication:sourceApplication
                               withSession:FBSession.activeSession];
    
    SHKFacebook *facebookSharer = [[SHKFacebook alloc] init];
    [facebookSharer authDidFinish:result];
    
    return result;
}

+ (void)handleWillTerminate {
    
    [[FBSession activeSession] close];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Facebook");
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file
{
    BOOL result = [SHKFacebookCommon canFacebookAcceptFile:file];
    return result;
}

+ (BOOL)canShareOffline
{
	return NO; // TODO - would love to make this work
}

+ (BOOL)canGetUserInfo
{
    return YES;
}

+ (BOOL)canShare {
    
    BOOL result = ![SHKFacebookCommon socialFrameworkAvailable];
    return result;
}

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{
	SHKLog(@"session:%@", [[FBSession activeSession] description]);
    BOOL result = [FBSession activeSession].state == FBSessionStateOpen || [FBSession activeSession].state == FBSessionStateCreatedTokenLoaded || [FBSession activeSession].state == FBSessionStateOpenTokenExtended;
    return result;
}

- (void)promptAuthorization
{
	
    [self saveItemForLater:SHKPendingShare];
    
    FBSession *authSession = [[FBSession alloc] initWithPermissions:SHKCONFIG(facebookReadPermissions)];
    //completion happens within class method handleOpenURL:sourceApplication
    [authSession openWithCompletionHandler:nil];
}

+ (NSString *)username {
    
    return [SHKFacebookCommon username];
}

+ (void)logout
{
	[SHKFacebook clearSavedItem];
    [FBSession openActiveSessionWithAllowLoginUI:NO]; //the session must be activated before clearing token
	[FBSession.activeSession closeAndClearTokenInformation];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFacebookUserInfo];
}


#pragma mark -
#pragma mark Share Form
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    NSArray *result = [SHKFacebookCommon shareFormFieldsForItem:self.item];
    return result;
}

- (BOOL)send {
    
    //user info only
    
    [self setQuiet:YES];
    [[SHK currentHelper] keepSharerReference:self];
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        [self FBUserInfoRequestHandlerCallback:connection result:result error:error];
    }];
    
    [self sendDidStart];
    return YES;
}

-(void)FBUserInfoRequestHandlerCallback:(FBRequestConnection *)connection
                                 result:(id) result
                                  error:(NSError *)error
{
	if (error) {
        SHKLog(@"FB user info request failed with error:%@", error);
        return;
    }
    
    [result convertNSNullsToEmptyStrings];
    [[NSUserDefaults standardUserDefaults] setObject:result forKey:kSHKFacebookUserInfo];
    [self sendDidFinish];
    [[SHK currentHelper] removeSharerReference:self];
}

@end
