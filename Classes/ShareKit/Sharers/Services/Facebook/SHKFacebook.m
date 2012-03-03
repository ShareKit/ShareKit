//
//  SHKFacebook.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.

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
#import "SHKConfiguration.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

static NSString *const kSHKStoredItemKey=@"kSHKStoredItem";
static NSString *const kSHKFacebookAccessTokenKey=@"kSHKFacebookAccessToken";
static NSString *const kSHKFacebookExpiryDateKey=@"kSHKFacebookExpiryDate";
static NSString *const kSHKFacebookUserInfo =@"kSHKFacebookUserInfo";

@interface SHKFacebook()

+ (Facebook*)facebook;
+ (void)flushAccessToken;
+ (NSString *)storedImagePath:(UIImage*)image;
+ (UIImage*)storedImage:(NSString*)imagePath;
- (void)showFacebookForm;

@end

@implementation SHKFacebook

- (void)dealloc
{
  if ([SHKFacebook facebook].sessionDelegate == self)
    [SHKFacebook facebook].sessionDelegate = nil;
	[super dealloc];
}

+ (Facebook*)facebook 
{
  static Facebook *facebook=nil;
  @synchronized([SHKFacebook class]) {
    if (! facebook)
      facebook = [[Facebook alloc] initWithAppId:SHKCONFIG(facebookAppId) urlSchemeSuffix:SHKCONFIG(facebookLocalAppId) andDelegate:nil];
  }
  return facebook;
}

+ (void)flushAccessToken 
{
  Facebook *facebook = [self facebook];
  facebook.accessToken = nil;
  facebook.expirationDate = nil;
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kSHKFacebookAccessTokenKey];
  [defaults removeObjectForKey:kSHKFacebookExpiryDateKey];
  [defaults removeObjectForKey:kSHKFacebookUserInfo];
  [defaults synchronize];
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
	
  NSString *uid = [NSString stringWithFormat:@"img-%i-%i", [[NSDate date] timeIntervalSince1970], arc4random()];    
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
  Facebook *fb = [SHKFacebook facebook];
  return [fb handleOpenURL:url];
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
  Facebook *facebook = [SHKFacebook facebook];
  if ([facebook isSessionValid]) return YES;
  
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  facebook.accessToken = [defaults stringForKey:kSHKFacebookAccessTokenKey];
  facebook.expirationDate = [defaults objectForKey:kSHKFacebookExpiryDateKey];
  return [facebook isSessionValid];
}

- (void)promptAuthorization
{
	NSMutableDictionary *itemRep = [NSMutableDictionary dictionaryWithDictionary:[self.item dictionaryRepresentation]];
	if (item.image)
	{
		[itemRep setObject:[SHKFacebook storedImagePath:item.image] forKey:@"imagePath"];
	}
	[[NSUserDefaults standardUserDefaults] setObject:itemRep forKey:kSHKStoredItemKey];
	
	[[SHKFacebook facebook] setSessionDelegate:self];
    [self retain]; //must retain, because FBConnect does not retain its delegates. Released in callback.
	[[SHKFacebook facebook] authorize:[NSArray arrayWithObjects:@"publish_stream", @"offline_access", nil]];		
}

+ (void)logout
{
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKStoredItemKey];
  [self flushAccessToken];
  [[self facebook] logout];
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
		if (item.text)
			[params setObject:item.text forKey:@"message"];
		NSString *pictureURI = [item customValueForKey:@"picture"];
		if (pictureURI)
			[params setObject:pictureURI forKey:@"picture"];
	}
	else if (item.shareType == SHKShareTypeText && item.text)
	{
		[params setObject:item.text forKey:@"message"];
        [[SHKFacebook facebook] requestWithGraphPath:@"me/feed"
                                           andParams:params
                                       andHttpMethod:@"POST"
                                         andDelegate:self];
        [self retain]; //must retain, because FBConnect does not retain its delegates. Released in callback.
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
		[[SHKFacebook facebook] requestWithGraphPath:@"me/photos"
										   andParams:params
									   andHttpMethod:@"POST"
										 andDelegate:self];
        [self retain]; //must retain, because FBConnect does not retain its delegates. Released in callback.
		return YES;
	}
    else if (item.shareType == SHKShareTypeUserInfo)
    {
        [self setQuiet:YES];
        [[SHKFacebook facebook] requestWithGraphPath:@"me" andDelegate:self];
        [self retain]; //must retain, because FBConnect does not retain its delegates. Released in callback.
        return YES;
    } 
	else 
		// There is nothing to send
		return NO;
	
	[[SHKFacebook facebook] dialog:@"feed"
						 andParams:params 
					   andDelegate:self];
    [self retain]; //must retain, because FBConnect does not retain its delegates. Released in callback.
    
	return YES;
}

#pragma mark -
#pragma mark FBDialogDelegate methods

- (void)dialogDidComplete:(FBDialog *)dialog
{
  [self sendDidFinish];  
    [self release]; //see [self send]
}

- (void)dialogDidNotComplete:(FBDialog *)dialog
{
  [self sendDidCancel];
    [self release]; //see [self send]
}

- (void)dialogCompleteWithUrl:(NSURL *)url 
{
  //if user presses cancel within webview FBDialogue, return string is without any other parameter, see issue #83. We should not show "Saved!".
  if ([[url absoluteString] isEqualToString:@"fbconnect://success"]) { 
      [self setQuiet:YES];
  }
  // error_code=190: user changed password or revoked access to the application,
  // so spin the user back over to authentication :
  NSRange errorRange = [[url absoluteString] rangeOfString:@"error_code=190"];
  if (errorRange.location != NSNotFound) 
  {
    [SHKFacebook flushAccessToken];
    [self authorize];
  }
}

- (void)dialogDidCancel:(FBDialog*)dialog
{
  [self sendDidCancel];
    [self release]; //see [self send]
}

- (void)dialog:(FBDialog *)dialog didFailWithError:(NSError *)error 
{
  if (error.code != NSURLErrorCancelled)
    [self sendDidFailWithError:error];
    [self release]; //see [self send]
}

- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url
{
    [self release]; //see [self promptAuthorization]. If callback happens, self will retain again.
	return YES;
    
}

#pragma mark FBSessionDelegate methods

- (void)fbDidLogin 
{
	NSString *accessToken = [[SHKFacebook facebook] accessToken];
	NSDate *expiryDate = [[SHKFacebook facebook] expirationDate];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:accessToken forKey:kSHKFacebookAccessTokenKey];
	[defaults setObject:expiryDate forKey:kSHKFacebookExpiryDateKey];
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
    [self authDidFinish:true];
	
    if (self.item)        
        [self tryPendingAction];
	
    [self release]; //see [self promptAuthorization]
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    
    if (!cancelled) {
        [[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
									 message:SHKLocalizedString(@"There was an error while authorizing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
    }
    
    [self authDidFinish:NO]; 
    [self release]; //see [self promptAuthorization]
}

#pragma mark FBRequestDelegate methods

- (void)requestLoading:(FBRequest *)request
{
  [self sendDidStart];
}

- (void)request:(FBRequest *)request didLoad:(id)result
{   
    if ([result objectForKey:@"username"]){
        
        [result convertNSNullsToEmptyStrings];
        [[NSUserDefaults standardUserDefaults] setObject:result forKey:kSHKFacebookUserInfo];
    }     

    [self sendDidFinish];
    [self release]; //see [self send]
}

- (void)request:(FBRequest*)aRequest didFailWithError:(NSError*)error 
{
    //if user revoked app permissions
    if (error.domain == @"facebookErrDomain" && error.code == 10000) {
        [self shouldReloginWithPendingAction:SHKPendingSend];
    } else {
        [self sendDidFailWithError:error];
    }
    
    [self release]; //see [self send]
}

#pragma mark -	
#pragma mark UI Implementation

- (void)show
{
    if (item.shareType == SHKShareTypeText)        
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
 	SHKFormControllerLargeTextField *rootView = [[SHKFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];  
 	rootView.text = item.text;
    
    self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
 	[self pushViewController:rootView animated:NO];
    [rootView release];
    
    [[SHK currentHelper] showViewController:self];  
}

- (void)sendForm:(SHKFormControllerLargeTextField *)form
{  
 	self.item.text = form.textView.text;
 	[self tryToSend];
}  

@end
