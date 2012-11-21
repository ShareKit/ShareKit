//
//  SHKSinaWeibo.m
//  ShareKit
//
//  Created by icyleaf on 12-03-16.
//  Copyright 2012 icyleaf.com. All rights reserved.

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


#import "SHKSinaWeibo.h"
#import "SHKConfiguration.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"
#import "JSONKit.h"
#import "SHKiOSSinaWeibo.h"

#import <Social/Social.h>

#define API_DOMAIN  @"http://api.t.sina.com.cn"

static NSString *const kSHKStoredItemKey=@"kSHKSinaWeiboStoredItem";
static NSString *const kSHKSinaWeiboAccessTokenKey=@"AccessTokenKey";
static NSString *const kSHKSinaWeiboExpiryDateKey=@"ExpirationDateKey";
static NSString *const kSHKSinaWeiboUserIdKey =@"UserIDKey";
static NSString *const kSHKSinaWeiboRefreshTokenKey =@"refresh_token";

static NSString *const kSHKSinaWeiboUserInfo = @"kSHKSinaWeiboUserInfo";

@interface SHKSinaWeibo ()

+ (SinaWeibo *)sinaWeibo;
+ (void)storeAuthData;
- (BOOL)prepareItem;
- (BOOL)shortenURL;
- (void)shortenURLFinished:(SHKRequest *)aRequest;
- (BOOL)validateItemAfterUserEdit;
- (BOOL)socialFrameworkAvailable;

- (void)showSinaWeiboForm;

@end

@implementation SHKSinaWeibo

+ (SinaWeibo *)sinaWeibo
{
    static SinaWeibo *sinaWeibo = nil;
    @synchronized([SHKSinaWeibo class]) {
        if (! sinaWeibo)
        {
            sinaWeibo = [[SinaWeibo alloc] initWithAppKey:SHKCONFIG(sinaWeiboConsumerKey)
                                                appSecret:SHKCONFIG(sinaWeiboConsumerSecret)
                                           appRedirectURI:SHKCONFIG(sinaWeiboCallbackUrl)
                                              andDelegate:nil];
            
            NSDictionary *sinaweiboInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKStoredItemKey];
            if ([sinaweiboInfo objectForKey:kSHKSinaWeiboAccessTokenKey]
                && [sinaweiboInfo objectForKey:kSHKSinaWeiboExpiryDateKey]
                && [sinaweiboInfo objectForKey:kSHKSinaWeiboUserIdKey])
            {
                sinaWeibo.accessToken = [sinaweiboInfo objectForKey:kSHKSinaWeiboAccessTokenKey];
                sinaWeibo.expirationDate = [sinaweiboInfo objectForKey:kSHKSinaWeiboExpiryDateKey];
                sinaWeibo.userID = [sinaweiboInfo objectForKey:kSHKSinaWeiboUserIdKey];
            }
        }
    }
    
    return sinaWeibo;
}

+ (void)storeAuthData
{
    SinaWeibo *sinaweibo = [SHKSinaWeibo sinaWeibo];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      sinaweibo.accessToken, kSHKSinaWeiboAccessTokenKey,
                                                      sinaweibo.expirationDate, kSHKSinaWeiboExpiryDateKey,
                                                      sinaweibo.userID, kSHKSinaWeiboUserIdKey,
                                                      sinaweibo.refreshToken, kSHKSinaWeiboRefreshTokenKey, nil]
                                              forKey:kSHKStoredItemKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)handleOpenURL:(NSURL*)url
{
    SinaWeibo *sinaWeibo = [SHKSinaWeibo sinaWeibo];
    
    // If app has "Application does not run in background" = YES,
    // or was killed before it could return from Facebook SSO callback (from Safari or Facebook app)
    if ( ! sinaWeibo.delegate)
    {
        SHKSinaWeibo *sinaWeiboSharer = [[SHKSinaWeibo alloc] init]; //released in sinaweiboDidLogIn
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kSHKStoredItemKey])
        {
            sinaWeiboSharer.pendingAction = SHKPendingShare;
        }
        
        [sinaWeibo setDelegate:sinaWeiboSharer];
    }
    
    return [sinaWeibo handleOpenURL:url];
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"新浪微博";
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
    SinaWeibo *sinaWeibo = [SHKSinaWeibo sinaWeibo];
    if ([sinaWeibo isAuthValid]) return YES;
    
    NSDictionary *sinaweiboInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKSinaWeiboAccessTokenKey];
    sinaWeibo.accessToken = [sinaweiboInfo objectForKey:kSHKSinaWeiboAccessTokenKey];
    sinaWeibo.expirationDate = [sinaweiboInfo objectForKey:kSHKSinaWeiboExpiryDateKey];
    sinaWeibo.userID = [sinaweiboInfo objectForKey:kSHKSinaWeiboUserIdKey];
    
    return [sinaWeibo isAuthValid];
}

- (void)promptAuthorization
{
	[[SHKSinaWeibo sinaWeibo] setDelegate:self];
    [self retain]; // must retain, because SinaWeibo does not retain its delegates. Released in callback.
	[[SHKSinaWeibo sinaWeibo] logIn];
}

+ (void)logout
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKStoredItemKey];
    [[SHKSinaWeibo sinaWeibo] logOut];
}

#pragma mark -
#pragma mark Commit Share

- (void)share 
{
    if ([self socialFrameworkAvailable])
    {
		SHKSharer *sharer =[SHKiOSSinaWeibo shareItem:self.item];
        sharer.quiet = self.quiet;
        sharer.shareDelegate = self.shareDelegate;
		[SHKSinaWeibo logout];// to clean credentials - we will not need them anymore
		return;
	}
    
	BOOL itemPrepared = [self prepareItem];
	
	// the only case item is not prepared is when we wait for URL to be shortened on background thread.
    // In this case [super share] is called in callback method
	if (itemPrepared) {
		[super share];
	}
}

- (BOOL)socialFrameworkAvailable
{
    if ([SHKCONFIG(forcePreSinaWeiboAccess) boolValue])
    {
        return NO;
    }
    
    if(NSClassFromString(@"SLComposeViewController") && [SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
        return YES;
    }
    
    return NO;
}

#pragma mark -

- (BOOL)prepareItem 
{
	BOOL result = YES;
	
	if (item.shareType == SHKShareTypeURL)
	{
		BOOL isURLAlreadyShortened = [self shortenURL];
		result = isURLAlreadyShortened;
	}
	
	else if (item.shareType == SHKShareTypeImage)
	{
		[item setCustomValue:item.title forKey:@"status"];
	}
	
	else if (item.shareType == SHKShareTypeText)
	{
		[item setCustomValue:item.text forKey:@"status"];
	}
	
	return result;
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    if (item.shareType == SHKShareTypeUserInfo)
	{
		[self setQuiet:YES];
		[self tryToSend];
	}
    
    else
    {
        [self showSinaWeiboForm];
    }
}

- (void)showSinaWeiboForm
{
	SHKCustomFormControllerLargeTextField *rootView = [[SHKCustomFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];
    
	rootView.text = [item customValueForKey:@"status"];
	rootView.maxTextLength = 140;
	rootView.image = item.image;
	rootView.imageTextLength = 25;
	
	self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
	
	[self pushViewController:rootView animated:NO];
	[rootView release];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKFormControllerLargeTextField *)form
{	
	[item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
}

#pragma mark -

- (BOOL)shortenURL
{
    if ([SHKCONFIG(sinaWeiboConsumerKey) isEqualToString:@""] || SHKCONFIG(sinaWeiboConsumerKey) == nil)
        NSAssert(NO, @"ShareKit: Could not shorting url with empty sina weibo consumer key.");
    
    if (![SHK connected])
	{
		[item setCustomValue:[NSString stringWithFormat:@"%@ %@", item.title, [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forKey:@"status"];
		return YES;
	}
    
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Shortening URL...")];
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[NSMutableString stringWithFormat:@"http://api.t.sina.com.cn/short_url/shorten.json?source=%@&url_long=%@",
																		  SHKCONFIG(sinaWeiboConsumerKey),						  
																		  SHKEncodeURL(item.URL)
																		  ]]
											 params:nil
										   delegate:self
								 isFinishedSelector:@selector(shortenURLFinished:)
											 method:@"GET"
										  autostart:YES] autorelease];
    
    return NO;
}

- (void)shortenURLFinished:(SHKRequest *)aRequest
{
	[[SHKActivityIndicator currentIndicator] hide];
        
    @try 
    {
        NSArray *result = [[aRequest getResult] objectFromJSONString];
        item.URL = [NSURL URLWithString:[[result objectAtIndex:0] objectForKey:@"url_short"]];
    }
    @catch (NSException *exception) 
    {
        // TODO - better error message
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Shorten URL Error")
									 message:SHKLocalizedString(@"We could not shorten the URL.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Continue")
						   otherButtonTitles:nil] autorelease] show];
    }
    
    [item setCustomValue:[NSString stringWithFormat:@"%@: %@", item.title, item.URL.absoluteString] 
                  forKey:@"status"];
	
	[super share];
}
	

#pragma mark -
#pragma mark Share API Methods

- (BOOL)validateItem
{
	if (self.item.shareType == SHKShareTypeUserInfo) {
		return YES;
	}
	
	NSString *status = [item customValueForKey:@"status"];
	return status != nil;
}

- (BOOL)validateItemAfterUserEdit 
{
	BOOL result = NO;
	
	BOOL isValid = [self validateItem];    
	NSString *status = [item customValueForKey:@"status"];
	
	if (isValid && status.length <= 140) {
		result = YES;
	}
	
	return result;
}

- (BOOL)send
{
	if ( ! [self validateItemAfterUserEdit])
		return NO;
	
	else
	{
        SinaWeibo *sinaweibo = [SHKSinaWeibo sinaWeibo];
        
        if (item.shareType == SHKShareTypeImage && item.image)
        {
            [sinaweibo requestWithURL:@"statuses/upload.json"
                               params:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [item customValueForKey:@"status"], @"status",
                                       item.image, @"pic", nil]
                           httpMethod:@"POST"
                             delegate:self];
		}
        
        else
        {
            [sinaweibo requestWithURL:@"statuses/update.json"
                               params:[NSMutableDictionary dictionaryWithObjectsAndKeys:[item customValueForKey:@"status"], @"status", nil]
                           httpMethod:@"POST"
                             delegate:self];
        }
        
        [self retain]; // must retain, because SinaWeibo does not retain its delegates. Released in callback.
		
		// Notify delegate
		[self sendDidStart];
		
		return YES;
	}
	
	return NO;
}

#pragma mark - Sina Weibo delegate methods

- (void)sinaweiboDidLogIn:(SinaWeibo *)sinaweibo
{
    [SHKSinaWeibo storeAuthData];
    
    [self authDidFinish:true];
	
    if (self.item)
        [self tryPendingAction];
}

- (void)sinaweiboDidLogOut:(SinaWeibo *)sinaweibo
{
    SHKLog(@"sinaweiboDidLogOut");
    [SHKSinaWeibo logout];
    
    [self release]; // see [self send]
}

- (void)sinaweiboLogInDidCancel:(SinaWeibo *)sinaweibo
{
    SHKLog(@"sinaweiboLogInDidCancel");
    
    [self authDidFinish:NO]; 
    [self release]; // see [self send]
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo logInDidFailWithError:(NSError *)error
{
    SHKLog(@"sinaweibo logInDidFailWithError %@", error);
    [self authDidFinish:NO];
    
    [self release]; // see [self send]
}

- (void)sinaweibo:(SinaWeibo *)sinaweibo accessTokenInvalidOrExpired:(NSError *)error
{
    SHKLog(@"sinaweiboAccessTokenInvalidOrExpired %@", error);
    [SHKSinaWeibo logout];
    
    [self authDidFinish:NO];
    
    [self release]; // see [self send]
}

#pragma mark - SinaWeiboRequest Delegate

- (void)request:(SinaWeiboRequest *)aRequest didFailWithError:(NSError *)error
{
    if ([aRequest.url hasSuffix:@"statuses/update.json"])
    {
        SHKLog(@"Post status failed with error : %@", error);
    }
    
    [self sendDidFailWithError:error];
    
    [self release]; // see [self send]
}

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)result
{
    [self sendDidFinish];
    [self release]; // see [self send]
}

@end
