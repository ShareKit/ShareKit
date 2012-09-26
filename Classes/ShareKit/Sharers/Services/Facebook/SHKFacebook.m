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
static NSString *const kSHKFacebookAccessTokenKey=@"kSHKFacebookAccessToken";
static NSString *const kSHKFacebookExpiryDateKey=@"kSHKFacebookExpiryDate";
static NSString *const kSHKFacebookUserInfo =@"kSHKFacebookUserInfo";

static SHKFacebook *authingSHKFacebook=nil;

@interface SHKFacebook()

+ (NSString *)storedImagePath:(UIImage*)image;
+ (UIImage*)storedImage:(NSString*)imagePath;
- (void)showFacebookForm;

- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLog;
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error;
@end

@implementation SHKFacebook
- (id)init
{
    self = [super init];
    if (self) {
		[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
    }
    return self;
}

- (void)dealloc
{
	[FBSession.activeSession close];	// unhooks this instance from the sessionStateChanged callback
	if (authingSHKFacebook == self) {
		authingSHKFacebook = nil;
	}
	[super dealloc];
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
						 permissions:SHKCONFIG(facebookListOfPermissions)
					 urlSchemeSuffix:SHKCONFIG(facebookLocalAppId)
				  tokenCacheStrategy:nil] autorelease];
    
    if (allowLoginUI ||
        (session.state == FBSessionStateCreatedTokenLoaded)) {
        [FBSession setActiveSession:session];
        [session openWithCompletionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
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
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *storedItem = [defaults objectForKey:kSHKStoredItemKey];
		if (storedItem)
		{
			self.item = [SHKItem itemFromDictionary:storedItem];
			NSString *imagePath = [storedItem objectForKey:@"imagePath"];
			if (imagePath) {
				self.item.image = [SHKFacebook storedImage:imagePath];
			}
			[defaults removeObjectForKey:kSHKStoredItemKey];
		}
		[defaults synchronize];
		if (authingSHKFacebook == self) {	
			[self authDidFinish:true];
		}
		
		if (self.item)
			[self tryPendingAction];
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
	//if app has "Application does not run in background" = YES, or was killed before it could return from Facebook SSO callback (from Safari or Facebook app)
	if (authingSHKFacebook == nil)
	{
		authingSHKFacebook = [[SHKFacebook alloc] init]; //released in sessionStateChanged
		
		if ([[NSUserDefaults standardUserDefaults] objectForKey:kSHKStoredItemKey])
		{
			authingSHKFacebook.pendingAction = SHKPendingShare;
		}
	}
    
	return [FBSession.activeSession handleOpenURL:url];
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
	NSMutableDictionary *itemRep = [NSMutableDictionary dictionaryWithDictionary:[self.item dictionaryRepresentation]];
	if (item.image)
	{
		[itemRep setObject:[SHKFacebook storedImagePath:item.image] forKey:@"imagePath"];
	}
	[[NSUserDefaults standardUserDefaults] setObject:itemRep forKey:kSHKStoredItemKey];
	
	authingSHKFacebook = self;
	[self retain];
	
	[self openSessionWithAllowLoginUI:YES];
}

+ (void)logout
{
	[FBSession setDefaultAppID:SHKCONFIG(facebookAppId)];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKStoredItemKey];
	[FBSession.activeSession closeAndClearTokenInformation];
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
 	if (![self validateItem])
		return NO;
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
		[FBRequestConnection startWithGraphPath:@"me/feed"
									 parameters:params
									 HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
										 [self FBRequestHandlerCallback:connection result:result error:error];
									 }];
		
		return YES;
	}
	else if (item.shareType == SHKShareTypeText && item.text)
	{
		[params setObject:item.text forKey:@"message"];
		[FBRequestConnection startWithGraphPath:@"me/feed"
									 parameters:params
									 HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
										 [self FBRequestHandlerCallback:connection result:result error:error];
									 }];
        return YES;
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
		[FBRequestConnection startWithGraphPath:@"me/photos"
									 parameters:params
									 HTTPMethod:@"POST" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
										 [self FBRequestHandlerCallback:connection result:result error:error];
									 }];
		return YES;
	}
    else if (item.shareType == SHKShareTypeUserInfo)
    {	// sharekit doesn't use this, I don't know who does
        [self setQuiet:YES];
		[FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
										 [self FBUserInfoRequestHandlerCallback:connection result:result error:error];
									 }];
        return YES;
    } 
	else 
		// There is nothing to send
		return NO;
	
}

-(void)FBUserInfoRequestHandlerCallback:(FBRequestConnection *)connection
						 result:(id) result
						  error:(NSError *)error
{
	[result convertNSNullsToEmptyStrings];
	[[NSUserDefaults standardUserDefaults] setObject:result forKey:kSHKFacebookUserInfo];
}

-(void)FBRequestHandlerCallback:(FBRequestConnection *)connection
						 result:(id) result
						  error:(NSError *)error
{
	if(error){
		//check if user revoked app permissions
		NSDictionary *response = [error.userInfo valueForKey:FBErrorParsedJSONResponseKey];
		
		if ([error.domain isEqualToString:FacebookSDKDomain] &&
			[[[[response objectForKey:@"body"] objectForKey:@"error"] objectForKey:@"code"] intValue] == 190) {
			[FBSession.activeSession closeAndClearTokenInformation];
			[self shouldReloginWithPendingAction:SHKPendingSend];
		} else {
			[self sendDidFailWithError:error];
		}
	}else{
		[self sendDidFinish];
	}

}

#pragma mark - UI Implementation

- (void)show
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
