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

#import "SHKiOSFacebook.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"
#import "SharersCommonHeaders.h"

#import <Social/Social.h>
#import <FacebookSDK/FacebookSDK.h>

static NSString *const kSHKFacebookUserInfo =@"kSHKFacebookUserInfo";
static NSString *const kSHKFacebookVideoUploadLimits =@"kSHKFacebookVideoUploadLimits";

// these are ways of getting back to the instance that made the request through statics
// there are two so that the logic of their lifetimes is understandable.
static SHKFacebook *authingSHKFacebook=nil;
static SHKFacebook *requestingPermisSHKFacebook=nil;

@interface SHKFacebook()

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLog;
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error;

- (void) doSend;
- (void) doNativeShow;

@property (readwrite,strong) NSMutableSet* pendingConnections;
@end

@implementation SHKFacebook

@synthesize pendingConnections;

- (id)init
{
    self = [super init];
    if (self) {
        self.pendingConnections = [[NSMutableSet alloc] init];
		[FBSettings setDefaultAppID:SHKCONFIG(facebookAppId)];
    }
    return self;
}

- (void)dealloc
{
	[self cancelPendingRequests];
	[FBSession.activeSession close];	// unhooks this instance from the sessionStateChanged callback
	if (authingSHKFacebook == self) {
		authingSHKFacebook = nil;
	}
	if (requestingPermisSHKFacebook == self) {
		requestingPermisSHKFacebook = nil;
	}
}

- (void)cancelPendingRequests{
	// since items are added and removed in the various handlers we're just
	// going to make a copy of the set before we start telling things to cancel
	// so that we don;t have to deal with having the collection be modified
	// while working on it.
	NSSet* tempSet = [NSSet setWithSet:self.pendingConnections];
	for (id conn in tempSet) {
		if ([conn respondsToSelector:@selector(cancel)]) {
			[conn cancel];
		}
	}
	[self.pendingConnections removeAllObjects];
}

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI {
	// because this routine is used both for checking if we are authed and
	// initiating auth we do a quick check to see if we have been through
	// the cycle. If we don't then we'll create an infinite loop due to the
	// upstream isAuthed then trytosend logic
	
	// keep in mind that this reoutine can return TRUE even if the store creds
	// are no longer valid. For example if the user has revolked the app from
	// their profile. In this case the stored tolken look like it should work,
	// but the first request will fail
	if(FBSession.activeSession.isOpen)
		return YES;
	
    BOOL result = NO;
    FBSession *session =
	[[FBSession alloc] initWithAppID:SHKCONFIG(facebookAppId)
						 permissions:SHKCONFIG(facebookReadPermissions)	// FB only wants read or publish so use default read, request publish when we need it
					 urlSchemeSuffix:SHKCONFIG(facebookLocalAppId)
				  tokenCacheStrategy:nil];
    
    if (allowLoginUI || (session.state == FBSessionStateCreatedTokenLoaded)) {
        
		if (allowLoginUI) [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
        
        [FBSession setActiveSession:session];
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
				completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
					if (allowLoginUI) [[SHKActivityIndicator currentIndicator] hide];
					[self sessionStateChanged:session state:state error:error];
				}];
        result = session.isOpen;
    }
	
    return result;
}

/*
 * Callback for session changes.
 */
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
	if(FB_ISSESSIONOPENWITHSTATE(state)){
		NSAssert(error == nil, @"ShareKit: Facebook sessionStateChanged open session, but errors?!?!");
		if(requestingPermisSHKFacebook == self){
			// in this case, we basically want to ignore the state change because the
			// completion handler for the permission request handles the post.
			// this happens when the permissions just get extended 
		}else{
			[self restoreItem];
			
			if (authingSHKFacebook == self) {
				[self authDidFinish:true];
			}
			
			[self tryPendingAction];
		}
	}else if (FB_ISSESSIONSTATETERMINAL(state)){
		if (authingSHKFacebook == self) {	// the state can change for a lot of reasons that are out of the login loop
			[self authDidFinish:NO];		// for exaple closing the session in dealloc.
		}else{
			// seems that if you expire the tolken that it thinks is valid it will close the session without reporting
			// errors super awesome. So look for the errors in the FBRequestHandlerCallback
		}
	}
	
	// post a notification so that custom UI can show the login state.
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"SHKFacebookSessionStateChangeNotification"
     object:session];
    
    if (error) {
		[FBSession.activeSession closeAndClearTokenInformation];
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
	if (authingSHKFacebook == self) {
		authingSHKFacebook = nil;
		[[SHK currentHelper] removeSharerReference:self];
	}
}

+ (BOOL)handleOpenURL:(NSURL*)url
{
	[FBSettings setDefaultAppID:SHKCONFIG(facebookAppId)];
	//if app has "Application does not run in background" = YES, or was killed before it could return from Facebook SSO callback (from Safari or Facebook app)
	if (authingSHKFacebook == nil &&
		requestingPermisSHKFacebook == nil)
	{
		[FBSession.activeSession close];	// close it down because we don't know about it
		authingSHKFacebook = [[SHKFacebook alloc] init];	//released in sessionStateChanged
															// resend is triggered in sessionStateChanged
	}
    
	return [FBSession.activeSession handleOpenURL:url];
}

+ (void)handleWillTerminate
{
	[FBSettings setDefaultAppID:SHKCONFIG(facebookAppId)];
	// if the app is going away, we close the session object; this is a good idea because
	// things may be hanging off the session, that need releasing (completion block, etc.) and
	// other components in the app may be awaiting close notification in order to do cleanup
	[FBSession.activeSession close];
}

+ (void)handleDidBecomeActive
{
	[FBSettings setDefaultAppID:SHKCONFIG(facebookAppId)];
	// We need to properly handle activation of the application with regards to SSO
	//  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
	[FBSession.activeSession handleDidBecomeActive];
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
	NSArray *facebookValidTypes = @[@"3g2",@"3gp" ,@"3gpp" ,@"asf",@"avi",@"dat",@"flv",@"m4v",@"mkv",@"mod",@"mov",@"mp4",
            @"mpe",@"mpeg",@"mpeg4",@"mpg",@"nsv",@"ogm",@"ogv",@"qt" ,@"tod",@"vob",@"wmv"];
    
    for (NSString *extension in facebookValidTypes) {
        if ([file.filename hasSuffix:extension]) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)canShareOffline
{
	return NO; // TODO - would love to make this work
}

+ (BOOL)canGetUserInfo
{
    return YES;
}

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{	  
	return [self openSessionWithAllowLoginUI:NO];
}

- (void)promptAuthorization
{
	[self saveItemForLater:SHKPendingShare];
	
	NSAssert(authingSHKFacebook == nil, @"ShareKit: auth loop logic error - will lead to leaks");
	authingSHKFacebook = self;
	[[SHK currentHelper] keepSharerReference:self];
	
	[self openSessionWithAllowLoginUI:YES];
}

+ (void)logout
{
	[SHKFacebook clearSavedItem];
	[FBSettings setDefaultAppID:SHKCONFIG(facebookAppId)];
	[FBSession.activeSession closeAndClearTokenInformation];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFacebookUserInfo];
}

#pragma mark -
#pragma mark Share Form
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    NSString *text;
    NSString *key;
    BOOL allowEmptyMessage = NO;
    
    switch (self.item.shareType) {
        case SHKShareTypeText:
            text = self.item.text;
            key = @"text";
            break;
        case SHKShareTypeImage:
            text = self.item.title;
            key = @"title";
            allowEmptyMessage = YES;
            break;
        case SHKShareTypeURL:
            text = self.item.text;
            key = @"text";
            allowEmptyMessage = YES;
            break;
        case SHKShareTypeFile:
            text = self.item.text;
            key = @"text";
            break;
        default:
            return nil;
    }
    
    NSMutableArray *result = [@[[SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Comment")
                                                                 key:key
                                                                type:SHKFormFieldTypeTextLarge
                                                               start:text
                                                       maxTextLength:0
                                                               image:self.item.image
                                                     imageTextLength:0
                                                                link:self.item.URL
                                                                file:self.item.file
                                                      allowEmptySend:allowEmptyMessage
                                                              select:YES]] mutableCopy];
    
    if (self.item.shareType == SHKShareTypeURL || self.item.shareType == SHKShareTypeFile) {
        SHKFormFieldSettings *title = [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title];
        [result insertObject:title atIndex:0];
    }
    return result;
}

- (void) doNativeShow
{
	BOOL displayedNativeDialog = [FBDialogs presentOSIntegratedShareDialogModallyFrom:[[SHK currentHelper] rootViewForUIDisplay]
                                                                          initialText:self.item.text ? self.item.text : self.item.title
                                                                                image:self.item.image
                                                                                  url:self.item.URL
                                                                              handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
                                                                                  if (error) {
                                                                                      /* handle failure */
                                                                                      //check if user revoked app permissions
                                                                                      NSDictionary *response = [error.userInfo valueForKey:FBErrorParsedJSONResponseKey];
                                                                                      
                                                                                      if ([error.domain isEqualToString:FacebookSDKDomain] &&
                                                                                          [[[[response objectForKey:@"body"] objectForKey:@"error"] objectForKey:@"code"] intValue] == 190) {
                                                                                          [FBSession.activeSession closeAndClearTokenInformation];
                                                                                          [self shouldReloginWithPendingAction:SHKPendingShare];
                                                                                      } else {
                                                                                          [self sendDidFailWithError:error];
                                                                                          [FBSession.activeSession close];	// unhook us
                                                                                      }
                                                                                  } else {
                                                                                      if (result == FBNativeDialogResultSucceeded) {
                                                                                          /* handle success */
                                                                                          [self sendDidFinish];
                                                                                          [FBSession.activeSession close];	// unhook us
                                                                                      } else {
                                                                                          /* handle user cancel */
                                                                                          [self sendDidCancel];
                                                                                      }
                                                                                  }
                                                                              }];
	if (!displayedNativeDialog) {
		[super show];
	}
}

- (void)show
{
	BOOL tryToPresent = ![SHKCONFIG(forcePreIOS6FacebookPosting) boolValue] && [FBDialogs canPresentOSIntegratedShareDialogWithSession:[FBSession activeSession]];
	if(tryToPresent){	// if there's a shot
		if ([FBSession.activeSession.permissions
			 indexOfObject:@"publish_actions"] == NSNotFound) {	// we need at least this.SHKCONFIG(facebookWritePermissions
			// No permissions found in session, ask for it
			[self saveItemForLater:SHKPendingSend];
			[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Authenticating...")];
			if(requestingPermisSHKFacebook == nil){
				requestingPermisSHKFacebook = self;
			}
			[FBSession.activeSession requestNewPublishPermissions:SHKCONFIG(facebookWritePermissions)
                                                  defaultAudience:FBSessionDefaultAudienceFriends
                                                completionHandler:^(FBSession *session, NSError *error) {
                                                    [self restoreItem];
                                                    [[SHKActivityIndicator currentIndicator] hide];
                                                    requestingPermisSHKFacebook = nil;
                                                    if (error) {
                                                        UIAlertView *alertView = [[UIAlertView alloc]
                                                                                  initWithTitle:@"Error"
                                                                                  message:error.localizedDescription
                                                                                  delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil];
                                                        [alertView show];
                                                        
                                                        [self sendDidCancel];
                                                    }else{
                                                        // If permissions granted, publish the story
                                                        [self doNativeShow];
                                                    }
                                                    // the session watcher handles the error
                                                }];
		} else {
			// If permissions present, publish the story
			[self doNativeShow];
		}
	}else{
		[super show];
	}
}

#pragma mark -
#pragma mark Share API Methods

- (void)share {
    
    if ([self socialFrameworkAvailable]) {
        
        SHKSharer *iosSharer = [SHKiOSFacebook shareItem:self.item];
        iosSharer.quiet = self.quiet;
        iosSharer.shareDelegate = self.shareDelegate;
        [SHKFacebook logout];
        
    } else {
        
        [super share];
    }   
}

- (BOOL)socialFrameworkAvailable {
    
    if (self.item.shareType == SHKShareTypeFile)
        return NO; // iOS6 sharing can't handle video
    
    if ([SHKCONFIG(forcePreIOS6FacebookPosting) boolValue])
        return NO;
    
	if (NSClassFromString(@"SLComposeViewController"))
		return YES;
	
	return NO;
}

-(void) sendDidCancel
{
	[super sendDidCancel];
	[self cancelPendingRequests];
	[FBSession.activeSession close];	// unhook us
}

- (void)sendDidFailWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
	[self cancelPendingRequests];
	[super sendDidFailWithError:error shouldRelogin:shouldRelogin];
}

- (BOOL)send
{
 	if (![self validateItem])
		return NO;
	
    // Ask for publish_actions permissions in context
    if (self.item.shareType != SHKShareTypeUserInfo &&[FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {	// we need at least this.SHKCONFIG(facebookWritePermissions
        // No permissions found in session, ask for it
        [self saveItemForLater:SHKPendingSend];
        [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Authenticating...")];
        if(requestingPermisSHKFacebook == nil){
            requestingPermisSHKFacebook = self;
        }
        [FBSession.activeSession requestNewPublishPermissions:SHKCONFIG(facebookWritePermissions)
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                            completionHandler:^(FBSession *session, NSError *error) {
                                                [self restoreItem];
                                                [[SHKActivityIndicator currentIndicator] hide];
                                                requestingPermisSHKFacebook = nil;
                                                if (error) {
                                                    
                                                    if (error.fberrorCategory == FBErrorCategoryUserCancelled) {
                                                        
                                                        [self sendDidCancel];
                                                        return;
                                                        
                                                    } else {
                                                        
                                                        UIAlertView *alertView = [[UIAlertView alloc]
                                                                                  initWithTitle:@"Error"
                                                                                  message:error.localizedDescription
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
    // Warning to modifiers of SEND, be sure that if send becomes more than a single FBRequestConnection
	// you properly deal with closing the session. For the moment we can close the session when these complete
	// and get un-retained by the session state callback.
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NSString *actions = [NSString stringWithFormat:@"{\"name\":\"%@ %@\",\"link\":\"%@\"}",
						 SHKLocalizedString(@"Get"), SHKCONFIG(appName), SHKCONFIG(appURL)];
	[params setObject:actions forKey:@"actions"];
	
	if (self.item.shareType == SHKShareTypeURL || self.item.shareType == SHKShareTypeText)
	{
        if (self.item.URL) {
            NSString *url = [self.item.URL absoluteString];
            [params setObject:url forKey:@"link"];
        }
        
        if (self.item.title) {
            [params setObject:self.item.title forKey:@"name"];
        }

		if (self.item.text)
			[params setObject:self.item.text forKey:@"message"];
		
		NSString *pictureURI = self.item.facebookURLSharePictureURI;
		if (pictureURI)
			[params setObject:pictureURI forKey:@"picture"];
		
		NSString *description = self.item.facebookURLShareDescription;
		if (description)
			[params setObject:description forKey:@"description"];
		FBRequestConnection* con = [FBRequestConnection startWithGraphPath:@"me/feed"
																parameters:params
																HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
																	[self FBRequestHandlerCallback:connection result:result error:error];
																}];
		[self.pendingConnections addObject:con];
		
	}
	else if (self.item.shareType == SHKShareTypeImage)
	{
        /*if (self.item.title)
			[params setObject:self.item.title forKey:@"caption"];*/ //caption apparently does not work
		if (self.item.title)
			[params setObject:self.item.title forKey:@"message"];
		[params setObject:self.item.image forKey:@"picture"];
		// There does not appear to be a way to add the photo
		// via the dialog option:
		FBRequestConnection* con = [FBRequestConnection startWithGraphPath:@"me/photos"
																 parameters:params
																 HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
																	 [self FBRequestHandlerCallback:connection result:result error:error];
																 }];
		[self.pendingConnections addObject:con];
	}
    else if (self.item.shareType == SHKShareTypeFile)
	{
        [self validateVideoLimits:^(NSError *error){
            
            if (error){
                [[SHKActivityIndicator currentIndicator] hide];
                [self sendDidFailWithError:error];
                [self sendDidFinish];
                return;
            }
            
            if (self.item.title)
                [params setObject:self.item.title forKey:@"title"];
            if (self.item.text)
                [params setObject:self.item.text forKey:@"description"];
            
            if (error) {
                [[SHKActivityIndicator currentIndicator] hide];
                [self sendDidFailWithError:error];
                [self sendDidFinish];
                return;
            }
            [params setObject:self.item.file.data forKey:self.item.file.filename];
            [params setObject:self.item.file.mimeType forKey:@"contentType"];
            FBRequestConnection* con = [FBRequestConnection startWithGraphPath:@"me/videos"
                                                                    parameters:params
                                                                    HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                                        [self FBRequestHandlerCallback:connection result:result error:error];
                                                                    }];
            [self.pendingConnections addObject:con];
        }];
	}
	else if (self.item.shareType == SHKShareTypeUserInfo)
	{	// sharekit demo app doesn't use this, handy if you need to show user info, such as user name for OAuth services in your app, see https://github.com/ShareKit/ShareKit/wiki/FAQ
		[self setQuiet:YES];
		FBRequestConnection* con = [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
			[self FBUserInfoRequestHandlerCallback:connection result:result error:error];
		}];
		[self.pendingConnections addObject:con];
	}
    [self sendDidStart];
}

-(void)validateVideoLimits:(void (^)(NSError *error))completionBlock
{
    // Validate against video size restrictions
    
    // Pull our constraints directly from facebook
    FBRequestConnection *con = [FBRequestConnection startWithGraphPath:@"me?fields=video_upload_limits" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(![self.pendingConnections containsObject:connection]){
            NSLog(@"SHKFacebook - received a callback for a connection not in the pending requests.");
        }
        [self.pendingConnections removeObject:connection];
        
        if(error){
            [[SHKActivityIndicator currentIndicator] hide];
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
            NSUInteger maxVideoDuration = (int)result[@"video_upload_limits"][@"length"];
            BOOL isUnderDuration = maxVideoDuration >= self.item.file.duration;
            if(!isUnderDuration){
                completionBlock([NSError errorWithDomain:@"video_upload_limits" code:200 userInfo:@{
                                NSLocalizedDescriptionKey:SHKLocalizedString(@"Video's duration is too long for upload to Facebook.")}]);
                return;
            }
            
            // Success!
            completionBlock(nil);
        }
    }];
    [self.pendingConnections addObject:con];
}

-(void)FBUserInfoRequestHandlerCallback:(FBRequestConnection *)connection
						 result:(id) result
						  error:(NSError *)error
{
	if(![self.pendingConnections containsObject:connection]){
		NSLog(@"SHKFacebook - received a callback for a connection not in the pending requests.");
	}
	[self.pendingConnections removeObject:connection];
	if (error) {
		[[SHKActivityIndicator currentIndicator] hide];
		[self sendDidFailWithError:error];
	}else{
		[result convertNSNullsToEmptyStrings];
		[[NSUserDefaults standardUserDefaults] setObject:result forKey:kSHKFacebookUserInfo];
		[self sendDidFinish];
	}
	[FBSession.activeSession close];	// unhook us
}

-(void)FBRequestHandlerCallback:(FBRequestConnection *)connection
						 result:(id) result
						  error:(NSError *)error
{
	if(![self.pendingConnections containsObject:connection]){
		SHKLog(@"SHKFacebook - received a callback for a connection not in the pending requests.");
	}
	[self.pendingConnections removeObject:connection];
	if(error){
		[[SHKActivityIndicator currentIndicator] hide];
		//check if user revoked app permissions
		NSDictionary *response = [error.userInfo valueForKey:FBErrorParsedJSONResponseKey];
        
        NSInteger code = [[response objectForKey:@"code"] intValue];
        NSInteger bodyCode = [[[[response objectForKey:@"body"] objectForKey:@"error"] objectForKey:@"code"] intValue];
		
		if (bodyCode == 190 || code == 403) {
			[FBSession.activeSession closeAndClearTokenInformation];
			[self shouldReloginWithPendingAction:SHKPendingSend];
		} else {
			[self sendDidFailWithError:error];
			[FBSession.activeSession close];	// unhook us
		}
	}else{
		[self sendDidFinish];
		[FBSession.activeSession close];	// unhook us
	}

}

@end
