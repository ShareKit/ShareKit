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

@interface SHKFacebook ()

///reference of an upload connection, so that it is cancellable (used in file/image uploads, which can report progress)
@property (nonatomic, weak) FBRequestConnection *fbRequestConnection;

@end

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
                               withSession:[FBSession activeSession]];
    
    SHKFacebook *facebookSharer = [[SHKFacebook alloc] init];
    BOOL itemRestored = [facebookSharer restoreItem];
    
    if (itemRestored) {
        FBSessionStateHandler handler = ^(FBSession *session, FBSessionState status, NSError *error) {
            
            if (error) {
                [facebookSharer saveItemForLater:facebookSharer.pendingAction];
                SHKLog(@"no read permissions: %@", [error description]);
            } else {
                
                //this allows for completion block to finish and continue sharing AFTER. Otherwise strange black windows and orphan webview login showed up.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [facebookSharer tryPendingAction];
                });
            }
        };
        
        if ([[FBSession activeSession] isOpen]) {
            handler([FBSession activeSession], [FBSession activeSession].state, nil);
        } else {
            NSRange rangeOfWritePermissions = [[url absoluteString] rangeOfString:SHKCONFIG(facebookWritePermissions)[0]];
            BOOL gotReadPermissionsOnly =  rangeOfWritePermissions.location == NSNotFound;
            if (gotReadPermissionsOnly) {
                [FBSession openActiveSessionWithReadPermissions:SHKCONFIG(facebookReadPermissions) allowLoginUI:NO completionHandler:handler];
            } else {
                [FBSession openActiveSessionWithPublishPermissions:SHKCONFIG(facebookWritePermissions) defaultAudience:FBSessionDefaultAudienceFriends allowLoginUI:NO completionHandler:handler];
            }
        }
    }
    
    if (result) {
        SHKFacebook *facebookSharer = [[SHKFacebook alloc] init];
        [facebookSharer authDidFinish:result];
    }
    
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
	//SHKLog(@"session is authorized:%@", [[FBSession activeSession] description]);
    BOOL result = [FBSession activeSession].state == FBSessionStateOpen || [FBSession activeSession].state == FBSessionStateCreatedTokenLoaded || [FBSession activeSession].state == FBSessionStateOpenTokenExtended;
    return result;
}

- (void)promptAuthorization
{
    [self saveItemForLater:SHKPendingShare];
    
    NSMutableArray* permissions = [NSMutableArray arrayWithArray:SHKCONFIG(facebookWritePermissions)];
    [permissions addObjectsFromArray:SHKCONFIG(facebookReadPermissions)];
    
    FBSession *authSession = [[FBSession alloc] initWithPermissions:permissions];
    
    //completion happens within class method handleOpenURL:sourceApplication, thus nil handler here
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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFacebookVideoUploadLimits];
}


#pragma mark -
#pragma mark Share Form
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    NSArray *result = [SHKFacebookCommon shareFormFieldsForItem:self.item];
    return result;
}

- (BOOL)send {
    
    if (![self validateItem])
		return NO;
    
    if (FBSession.activeSession.state != FBSessionStateOpen && FBSession.activeSession.state != FBSessionStateOpenTokenExtended && FBSession.activeSession.state != FBSessionStateCreatedOpening) {
        [[FBSession activeSession] openWithCompletionHandler:nil];
    }
	
    // Ask for publish_actions permissions in context
    if (self.item.shareType != SHKShareTypeUserInfo && ([[FBSession activeSession] permissions] == nil || [FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound)) {	// we need at least this.SHKCONFIG(facebookWritePermissions
        // No permissions found in session, ask for it
        [self saveItemForLater:SHKPendingSend];
        [self displayActivity:SHKLocalizedString(@"Authenticating...")];

        [FBSession.activeSession requestNewPublishPermissions:SHKCONFIG(facebookWritePermissions)
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                [self restoreItem];
                                                [self hideActivityIndicator];

                                                if (error) {
                                                    
                                                    if (error.fberrorCategory == FBErrorCategoryUserCancelled) {
                                                        
                                                        [self sendDidCancel];
                                                        return;
                                                        
                                                    } else if (error.fberrorShouldNotifyUser){
                                                        
                                                        UIAlertView *alertView = [[UIAlertView alloc]
                                                                                  initWithTitle:@"Error"
                                                                                  message:error.fberrorUserMessage
                                                                                  delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil];
                                                        [alertView show];
                                                        
                                                        self.pendingAction = SHKPendingShare;	// flip back to here so they can cancel
                                                        [self tryPendingAction];
                                                    }
                                                    
                                                }else{
                                                    // If permissions granted, publish the story
                                                    [self doSend];
                                                }
                                                // the session watcher handles the error
                                            }];
    } else {
        
        // If permissions present, publish the story
        [self doSend];
    }
    
    return YES;
}

- (void)doSend
{
	NSMutableDictionary *params = [SHKFacebookCommon composeParamsForItem:self.item];
	
	if (self.item.shareType == SHKShareTypeURL || self.item.shareType == SHKShareTypeText)
	{
		[FBRequestConnection startWithGraphPath:@"me/feed"
                                     parameters:params
                                     HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                         [self FBRequestHandlerCallback:connection result:result error:error];
                                     }];

	}
	else if (self.item.shareType == SHKShareTypeImage)
	{
        /*if (self.item.title)
         [params setObject:self.item.title forKey:@"caption"];*/ //caption apparently does not work
		[params setObject:self.item.image forKey:@"picture"];
		// There does not appear to be a way to add the photo
		// via the dialog option:
		self.fbRequestConnection = [FBRequestConnection startWithGraphPath:@"me/photos"
                                                                parameters:params
                                                                HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                                    [self FBRequestHandlerCallback:connection result:result error:error];
                                                                }];
        self.fbRequestConnection.delegate = self;
	}
    else if (self.item.shareType == SHKShareTypeFile)
	{
        [self validateVideoLimits:^(NSError *error){
            
            if (error){
                [self hideActivityIndicator];
                [self sendDidFailWithError:error];
                [self sendDidFinish];
                return;
            }
            
            [params setObject:self.item.file.data forKey:self.item.file.filename];
            [params setObject:self.item.file.mimeType forKey:@"contentType"];
            self.fbRequestConnection = [FBRequestConnection startWithGraphPath:@"me/videos"
                                                                    parameters:params
                                                                    HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                                        [self FBRequestHandlerCallback:connection result:result error:error];
                                                                    }];
            self.fbRequestConnection.delegate = self;
        }];
	}
	else if (self.item.shareType == SHKShareTypeUserInfo)
	{
        [self setQuiet:YES];
        [[SHK currentHelper] keepSharerReference:self];
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            [self FBUserInfoRequestHandlerCallback:connection result:result error:error];
        }];
    }
    
    [self sendDidStart];
}

- (void)cancel {
    
    [self.fbRequestConnection cancel];
    [self sendDidCancel];
}

-(void)FBRequestHandlerCallback:(FBRequestConnection *)connection
						 result:(id) result
						  error:(NSError *)error
{

	if(error){
		[self hideActivityIndicator];
		//check if user revoked app permissions
		NSDictionary *response = [error.userInfo valueForKey:FBErrorParsedJSONResponseKey];
        
        NSInteger code = [[response objectForKey:@"code"] intValue];
        NSInteger bodyCode = [[[[response objectForKey:@"body"] objectForKey:@"error"] objectForKey:@"code"] intValue];
		
		if (bodyCode == 190 || code == 403) {
			[FBSession.activeSession closeAndClearTokenInformation];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFacebookUserInfo];
			[self shouldReloginWithPendingAction:SHKPendingSend];
		} else {
			[self sendDidFailWithError:error];
			//[FBSession.activeSession close];	// unhook us
		}
	}else{
		[self sendDidFinish];
		//[FBSession.activeSession close];	// unhook us
	}
    
}

-(void)validateVideoLimits:(void (^)(NSError *error))completionBlock
{
    // Validate against video size restrictions
    
    // Pull our constraints directly from facebook
    [FBRequestConnection startWithGraphPath:@"me?fields=video_upload_limits" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        
        if(error){
            [self hideActivityIndicator];
            [self sendDidFailWithError:error];
            
            return;
        }else{
            // Parse and store - for possible future reference
            [result convertNSNullsToEmptyStrings];
            [[NSUserDefaults standardUserDefaults] setObject:result forKey:kSHKFacebookVideoUploadLimits];
            
            // Check video size
            NSUInteger maxVideoSize = [result[@"video_upload_limits"][@"size"] unsignedIntegerValue];
            BOOL isUnderSize = maxVideoSize >= self.item.file.size;
            if(!isUnderSize){
                completionBlock([NSError errorWithDomain:@"video_upload_limits" code:200 userInfo:@{
                                                                                                    NSLocalizedDescriptionKey:SHKLocalizedString(@"Video's file size is too large for upload to Facebook.")}]);
                return;
            }
            
            // Check video duration
            NSNumber *maxVideoDuration = result[@"video_upload_limits"][@"length"];
            BOOL isUnderDuration = [maxVideoDuration integerValue] >= self.item.file.duration;
            if(!isUnderDuration){
                completionBlock([NSError errorWithDomain:@"video_upload_limits" code:200 userInfo:@{
                                                                                                    NSLocalizedDescriptionKey:SHKLocalizedString(@"Video's duration is too long for upload to Facebook.")}]);
                return;
            }
            
            // Success!
            completionBlock(nil);
        }
    }];
}

- (void)FBUserInfoRequestHandlerCallback:(FBRequestConnection *)connection
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

#pragma mark - FBRequestConnectionDelegate methods

- (void)requestConnection:(FBRequestConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
    [self showUploadedBytes:totalBytesWritten totalBytes:totalBytesExpectedToWrite];
}


@end
