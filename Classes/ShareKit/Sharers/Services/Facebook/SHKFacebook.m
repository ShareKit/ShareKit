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
#import <FacebookSDK.h>
#import "SHKConfiguration.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

static NSString *const kSHKStoredItemKey=@"kSHKStoredItem";
static NSString *const kSHKStoredActionKey=@"kSHKStoredAction";
static NSString *const kSHKFacebookUserInfo =@"kSHKFacebookUserInfo";

// these are ways of getting back to the instance that made the request through statics
// there are two so that the logic of their lifetimes is understandable.
static SHKFacebook *authingSHKFacebook=nil;
static SHKFacebook *requestingPermisSHKFacebook=nil;

@interface SHKFacebook()

+ (NSString *)storedImagePath:(UIImage*)image;
+ (UIImage*)storedImage:(NSString*)imagePath;
- (void)showFacebookForm;

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLog;
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error;

- (void)saveItemForLater:(SHKSharerPendingAction)inPendingAction;
- (BOOL)restoreItem;

- (void) doSend;
- (void) doNativeShow;
- (void) doSHKShow;

@property (readwrite,retain) NSMutableSet* pendingConnections;
@end

@implementation SHKFacebook

@synthesize pendingConnections;

- (id)init
{
    self = [super init];
    if (self) {
        self.pendingConnections = [[[NSMutableSet alloc] init] autorelease];
		[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
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
	[super dealloc];
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


- (BOOL)restoreItem{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *storedItem = [defaults objectForKey:kSHKStoredItemKey];
	if (storedItem)
	{
		self.item = [SHKItem itemFromDictionary:storedItem];
		self.pendingAction = [[storedItem objectForKey:kSHKStoredActionKey] intValue];
		NSString *imagePath = [storedItem objectForKey:@"imagePath"];
		if (imagePath) {
			self.item.image = [SHKFacebook storedImage:imagePath];
		}
		[SHKFacebook clearSavedItem];
	}
	[defaults synchronize];

	return storedItem != nil;
}

- (void)saveItemForLater:(SHKSharerPendingAction)inPendingAction{
	NSMutableDictionary *itemRep = [NSMutableDictionary dictionaryWithDictionary:[self.item dictionaryRepresentation]];
	if (item.image)
	{
		[itemRep setObject:[SHKFacebook storedImagePath:item.image] forKey:@"imagePath"];
	}
	[itemRep setObject:[NSNumber numberWithInt:inPendingAction] forKey:kSHKStoredActionKey];
	[[NSUserDefaults standardUserDefaults] setObject:itemRep forKey:kSHKStoredItemKey];
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
	[[[FBSession alloc] initWithAppID:SHKCONFIG(facebookAppId)
						 permissions:SHKCONFIG(facebookReadPermissions)	// FB only wants read or publish so use default read, request publish when we need it
					 urlSchemeSuffix:SHKCONFIG(facebookLocalAppId)
				  tokenCacheStrategy:nil] autorelease];
    
    if (allowLoginUI ||
        (session.state == FBSessionStateCreatedTokenLoaded)) {
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
        [FBSession setActiveSession:session];
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
				completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
					[[SHKActivityIndicator currentIndicator] hide];
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
		[self release];
	}
}

+ (NSString *)storedImagePath:(UIImage*)image
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cache = [paths objectAtIndex:0];
	NSString *imagePath = [cache stringByAppendingPathComponent:@"SHKImage"];
	
	// Check if the path exists, otherwise create it
	if (![fileManager fileExistsAtPath:imagePath])
		[fileManager createDirectoryAtPath:imagePath withIntermediateDirectories:YES attributes:nil error:nil];
	
	NSString *uid = [NSString stringWithFormat:@"img-%f-%i", [[NSDate date] timeIntervalSince1970], arc4random()];
	// store image in cache
	NSData *imageData = UIImagePNGRepresentation(image);
	imagePath = [imagePath stringByAppendingPathComponent:uid];
	[imageData writeToFile:imagePath atomically:YES];
	
	return imagePath;
}

+ (UIImage*)storedImage:(NSString*)imagePath {
	NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
	UIImage *image = nil;
	if (imageData) {
		image = [UIImage imageWithData:imageData];
	}
	// Unlink the stored file:
	[[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
	return image;
}

+ (BOOL)handleOpenURL:(NSURL*)url
{
	[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
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
	[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
	// if the app is going away, we close the session object; this is a good idea because
	// things may be hanging off the session, that need releasing (completion block, etc.) and
	// other components in the app may be awaiting close notification in order to do cleanup
	[FBSession.activeSession close];
}

+ (void)handleDidBecomeActive
{
	[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
	// We need to properly handle activation of the application with regards to SSO
	//  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
	[FBSession.activeSession handleDidBecomeActive];
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Facebook";
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

+ (BOOL)canShareOffline
{
	return NO; // TODO - would love to make this work
}

+ (BOOL)canGetUserInfo
{
    return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return NO;
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
	[self retain];
	
	[self openSessionWithAllowLoginUI:YES];
}

+ (void)clearSavedItem{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	[defaults removeObjectForKey:kSHKStoredItemKey];
	[defaults removeObjectForKey:kSHKStoredActionKey];
	[defaults synchronize];
}

+ (void)logout
{
	[SHKFacebook clearSavedItem];
	[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
	[FBSession.activeSession closeAndClearTokenInformation];
}

#pragma mark -
#pragma mark Share API Methods
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
	
	if ((item.shareType == SHKShareTypeURL && item.URL)||
		(item.shareType == SHKShareTypeText && item.text)||
		(item.shareType == SHKShareTypeImage && item.image)||
		item.shareType == SHKShareTypeUserInfo)					// sharekit doesn't use this, I don't know who does
    {
		// Ask for publish_actions permissions in context
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

															 self.pendingAction = SHKPendingShare;	// flip back to here so they can cancel
															 [self tryPendingAction];
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
    } else {
		// There is nothing to send
		return NO;
	}
}

- (void)doSend
{
	// Warning to modifiers of SEND, be sure that if send becomes more than a single FBRequestConnection
	// you properly deal with closing the session. For the moment we can close the session when these complete
	// and get un-retained by the session state callback.
	[self sendDidStart];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	NSString *actions = [NSString stringWithFormat:@"{\"name\":\"%@ %@\",\"link\":\"%@\"}",
						 SHKLocalizedString(@"Get"), SHKCONFIG(appName), SHKCONFIG(appURL)];
	[params setObject:actions forKey:@"actions"];
	
	if (item.shareType == SHKShareTypeURL && item.URL)
	{
		NSString *url = [item.URL absoluteString];
		[params setObject:url forKey:@"link"];
		[params setObject:item.title == nil ? url : item.title
				   forKey:@"name"];
		
		//message parameter is invalid since 2011. Next two lines are useless.
		if (item.text)
			[params setObject:item.text forKey:@"message"];
		
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
	else if (item.shareType == SHKShareTypeText && item.text)
	{
		[params setObject:item.text forKey:@"message"];
		FBRequestConnection* con = [FBRequestConnection startWithGraphPath:@"me/feed"
																 parameters:params
																 HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
									 {
										 [self FBRequestHandlerCallback:connection result:result error:error];
									 }];
		[self.pendingConnections addObject:con];

	}
	else if (item.shareType == SHKShareTypeImage && item.image)
	{
		if (item.title)
			[params setObject:item.title forKey:@"caption"];
		if (item.text)
			[params setObject:item.text forKey:@"message"];
		[params setObject:item.image forKey:@"picture"];
		// There does not appear to be a way to add the photo
		// via the dialog option:
		FBRequestConnection* con = [FBRequestConnection startWithGraphPath:@"me/photos"
																 parameters:params
																 HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
																	 [self FBRequestHandlerCallback:connection result:result error:error];
																 }];
		[self.pendingConnections addObject:con];
	}
	else if (item.shareType == SHKShareTypeUserInfo)
	{	// sharekit doesn't use this, I don't know who does
		[self setQuiet:YES];
		FBRequestConnection* con = [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
			[self FBUserInfoRequestHandlerCallback:connection result:result error:error];
		}];
		[self.pendingConnections addObject:con];
	}
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
		NSLog(@"SHKFacebook - received a callback for a connection not in the pending requests.");
	}
	[self.pendingConnections removeObject:connection];
	if(error){
		[[SHKActivityIndicator currentIndicator] hide];
		//check if user revoked app permissions
		NSDictionary *response = [error.userInfo valueForKey:FBErrorParsedJSONResponseKey];
		
		if ([error.domain isEqualToString:FacebookSDKDomain] &&
			[[[[response objectForKey:@"body"] objectForKey:@"error"] objectForKey:@"code"] intValue] == 190) {
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

#pragma mark - UI Implementation
- (void) doNativeShow
{
	BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:[[SHK currentHelper] rootViewForCustomUIDisplay]
																	initialText:item.text ? item.text : item.title
																		  image:item.image
																			url:item.URL
																		handler:^(FBNativeDialogResult result, NSError *error) {
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
		[self doSHKShow];
	}
}

- (void) doSHKShow
{
    if (item.shareType == SHKShareTypeText || item.shareType == SHKShareTypeImage)
    {
        [self showFacebookForm];
    }
 	else
    {
        [self tryToSend];
    }
}

- (void)show
{
	BOOL tryToPresent = ![SHKCONFIG(forcePreIOS6FacebookPosting) boolValue] && [FBNativeDialogs canPresentShareDialogWithSession:[FBSession activeSession]];
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
		[self doSHKShow];
	}
}


- (void)showFacebookForm
{
 	SHKCustomFormControllerLargeTextField *rootView = [[SHKCustomFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];  
 	
    switch (self.item.shareType) {
        case SHKShareTypeText:
            rootView.text = item.text;
            break;
        case SHKShareTypeImage:
            rootView.image = item.image;
            rootView.text = item.title;            
        default:
            break;
    }    
    
    self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
 	[self pushViewController:rootView animated:NO];
    [rootView release];
    
    [[SHK currentHelper] showViewController:self];  
}

- (void)sendForm:(SHKCustomFormControllerLargeTextField *)form
{  
 	switch (self.item.shareType) {
        case SHKShareTypeText:
            self.item.text = form.textView.text;
            break;
        case SHKShareTypeImage:
            self.item.title = form.textView.text;
        default:
            break;
    }    
    
 	[self tryToSend];
}  

@end
