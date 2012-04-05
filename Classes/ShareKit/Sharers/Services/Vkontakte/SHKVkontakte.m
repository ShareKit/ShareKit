//
//  SHKVkontakte.m
//  ShareKit
//
//  Created by Alterplay Team on 05.12.11.
//  Based on https://github.com/maiorov/VKAPI
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

#import "SHKVkontakte.h"
#import "SHKConfiguration.h"
#import "SHKVkontakteOAuthView.h"
#import "JSONKit.h"

@interface SHKVkontakte()

- (void)showVkontakteForm;
- (void)getCaptcha;
- (NSDictionary *)sendRequest:(NSString *)reqURl withCaptcha:(BOOL)captcha;
- (NSDictionary *)sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData;
- (BOOL)sendTextAndLink;
- (BOOL)sendImageAction;
- (BOOL)sendText;
- (NSString *)URLEncodedString:(NSString *)str;

@end

@implementation SHKVkontakte

@synthesize accessUserId;
@synthesize accessToken;
@synthesize expirationDate;

+ (void)flushAccessToken 
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kSHKVkonakteUserId];
  [defaults removeObjectForKey:kSHKVkontakteAccessTokenKey];
  [defaults removeObjectForKey:kSHKVkontakteExpiryDateKey];
  [defaults synchronize];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Vkontakte";
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareOffline
{
	return NO; // TODO - would love to make this work
}

+ (BOOL)canGetUserInfo
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
#pragma mark Authentication

- (BOOL)isAuthorized
{	  
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	self.accessUserId = [standardUserDefaults objectForKey:kSHKVkonakteUserId];
	self.accessToken = [standardUserDefaults objectForKey:kSHKVkontakteAccessTokenKey];
	self.expirationDate = [standardUserDefaults objectForKey:kSHKVkontakteExpiryDateKey];
	
	return (self.accessToken != nil && self.expirationDate != nil
					&& NSOrderedDescending == [self.expirationDate compare:[NSDate date]]);
}

- (void)promptAuthorization
{	
	SHKVkontakteOAuthView *rootView = [[SHKVkontakteOAuthView alloc] init];
	rootView.appID = SHKCONFIG(vkontakteAppId);
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
	self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,rootView);
	
	[self pushViewController:rootView animated:NO];
	[rootView release];
	
	[[SHK currentHelper] showViewController:self];
}

- (void) authComplete 
{
	if (self.item) 
		[self share];
}

+ (void)logout
{
	/*
    NSString *logout = @"http://api.vk.com/oauth/logout";
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:logout] 
																												 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
																										 timeoutInterval:60.0]; 
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	if(responseData)
	{
		NSDictionary *dict = [[JSONDecoder decoder] parseJSONData:responseData];
	}*/
	
  [self flushAccessToken];
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{			
 	if (![self validateItem])
		return NO;
	
	[self setQuiet:NO];
	
	if (item.shareType == SHKShareTypeURL && item.URL)
	{
		[self sendTextAndLink];
		return YES;
	}
	else if (item.shareType == SHKShareTypeText && item.text)
	{
		[self sendText];
		return YES;
	}	
	else if (item.shareType == SHKShareTypeImage && item.image)
	{	
		[self sendImageAction];
		return YES;
	}
	else if (item.shareType == SHKShareTypeUserInfo)
	{
		/*[self setQuiet:YES];
		[[SHKFacebook facebook] requestWithGraphPath:@"me" andDelegate:self];
		return YES;*/
		return NO;
	} 
	else 
		return NO;

	return [self sendText];
}


#pragma mark -	
#pragma mark UI Implementation

- (void)show
{
	if (item.shareType == SHKShareTypeText)        
	{
		[self showVkontakteForm];
	}
 	else
	{
		[self tryToSend];
	}
}

- (void)showVkontakteForm
{
 	SHKCustomFormControllerLargeTextField *rootView = [[SHKCustomFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];  
    
 	rootView.text = item.text;
	self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
 	[self pushViewController:rootView animated:NO];
	[rootView release];
	[[SHK currentHelper] showViewController:self];  
}

- (void)sendForm:(SHKCustomFormControllerLargeTextField *)form
{  
 	self.item.text = form.textView.text;
 	[self tryToSend];
}

//Private
- (BOOL)sendImageAction 
{
	UIImage *image = item.image;

	NSString *getWallUploadServer = [NSString stringWithFormat:@"https://api.vk.com/method/photos.getWallUploadServer?owner_id=%@&access_token=%@", self.accessUserId, self.accessToken];
	
	NSDictionary *uploadServer = [self sendRequest:getWallUploadServer withCaptcha:NO];
	NSString *upload_url = [[uploadServer objectForKey:@"response"] objectForKey:@"upload_url"];
	
	NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
	
	NSDictionary *postDictionary = [self sendPOSTRequest:upload_url withImageData:imageData];
	
	NSString *hash = [postDictionary objectForKey:@"hash"];
	NSString *photo = [postDictionary objectForKey:@"photo"];
	NSString *server = [postDictionary objectForKey:@"server"];

	NSString *saveWallPhoto = [NSString stringWithFormat:@"https://api.vk.com/method/photos.saveWallPhoto?owner_id=%@&access_token=%@&server=%@&photo=%@&hash=%@", self.accessUserId, self.accessToken ,server, photo, hash];
	
	NSDictionary *saveWallPhotoDict = [self sendRequest:saveWallPhoto withCaptcha:NO];
	
	NSDictionary *photoDict = [[saveWallPhotoDict objectForKey:@"response"] lastObject];
	NSString *photoId = [photoDict objectForKey:@"id"];
	
	NSString *postToWallLink = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@&attachment=%@", self.accessUserId, self.accessToken, [self URLEncodedString:item.title], photoId];
	
	NSDictionary *postToWallDict = [self sendRequest:postToWallLink withCaptcha:NO];
	NSString *errorMsg = [[postToWallDict  objectForKey:@"error"] objectForKey:@"error_msg"];

	if(errorMsg) 
	{
		[self sendDidFailWithError:[NSError errorWithDomain:errorMsg code:1 userInfo:[NSDictionary dictionary]]];
		return NO;
	} 
	else 
	{
		[self sendDidFinish];
		return YES;
	}	
}

- (void) getCaptcha 
{
	NSString *captcha_img = [[NSUserDefaults standardUserDefaults] objectForKey:@"captcha_img"];
	UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Введите код:\n\n\n\n\n"
																												message:@"\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	
	UIImageView *imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(12.0, 45.0, 130.0, 50.0)] autorelease];
	imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:captcha_img]]];
	[myAlertView addSubview:imageView];
	
	UITextField *myTextField = [[[UITextField alloc] initWithFrame:CGRectMake(12.0, 110.0, 260.0, 25.0)] autorelease];
	[myTextField setBackgroundColor:[UIColor whiteColor]];
	
	myTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	myTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	myTextField.tag = 33;
	
	[myAlertView addSubview:myTextField];
	[myAlertView show];
	[myAlertView release];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(isCaptcha && buttonIndex == 1)
	{
		isCaptcha = NO;
		
		UITextField *myTextField = (UITextField *)[actionSheet viewWithTag:33];
		[[NSUserDefaults standardUserDefaults] setObject:myTextField.text forKey:@"captcha_user"];
		
		NSString *requestM = [[NSUserDefaults standardUserDefaults] objectForKey:@"request"];

		[self sendRequest:requestM withCaptcha:YES];
	}
}

- (BOOL) sendText 
{		
	NSString *sendTextMessage = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@", self.accessUserId, self.accessToken, [self URLEncodedString:item.text]];
	
	NSDictionary *result = [self sendRequest:sendTextMessage withCaptcha:NO];

	NSString *errorMsg = [[result objectForKey:@"error"] objectForKey:@"error_msg"];
	if(errorMsg) 
	{
		[self sendDidFailWithError:[NSError errorWithDomain:errorMsg code:1 userInfo:[NSDictionary dictionary]]];
		return NO;
	} 
	else 
	{
		[self sendDidFinish];
		return YES;
	}	
}

- (BOOL) sendTextAndLink 
{	
	NSString *sendTextAndLinkMessage = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@&attachment=%@", self.accessUserId, self.accessToken, [self URLEncodedString:item.text]?[self URLEncodedString:item.text]:[item.URL absoluteString], [item.URL absoluteString]];
	
	NSDictionary *result = [self sendRequest:sendTextAndLinkMessage withCaptcha:NO];
	NSString *errorMsg = [[result objectForKey:@"error"] objectForKey:@"error_msg"];
	if(errorMsg) 
	{
		[self sendDidFailWithError:[NSError errorWithDomain:errorMsg code:1 userInfo:[NSDictionary dictionary]]];
		return NO;
	} 
	else 
	{
		[self sendDidFinish];
		return YES;
	}	
}

- (NSDictionary *) sendRequest:(NSString *)reqURl withCaptcha:(BOOL)captcha 
{
	if(captcha == YES)
	{
		NSString *captcha_sid = [[NSUserDefaults standardUserDefaults] objectForKey:@"captcha_sid"];
		NSString *captcha_user = [[NSUserDefaults standardUserDefaults] objectForKey:@"captcha_user"];

		reqURl = [reqURl stringByAppendingFormat:@"&captcha_sid=%@&captcha_key=%@", captcha_sid, [self URLEncodedString: captcha_user]];
	}
	NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:reqURl] 
																												 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
																										 timeoutInterval:60.0]; 
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:requestM returningResponse:nil error:nil];
	
	if(responseData){
		NSDictionary *dict = [[JSONDecoder decoder] parseJSONData:responseData];
		
		NSString *errorMsg = [[dict objectForKey:@"error"] objectForKey:@"error_msg"];
		
		if([errorMsg isEqualToString:@"Captcha needed"])
		{
			isCaptcha = YES;

			NSString *captcha_sid = [[dict objectForKey:@"error"] objectForKey:@"captcha_sid"];
			NSString *captcha_img = [[dict objectForKey:@"error"] objectForKey:@"captcha_img"];
			[[NSUserDefaults standardUserDefaults] setObject:captcha_img forKey:@"captcha_img"];
			[[NSUserDefaults standardUserDefaults] setObject:captcha_sid forKey:@"captcha_sid"];

			[[NSUserDefaults standardUserDefaults] setObject:reqURl forKey:@"request"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
			[self getCaptcha];
		}
		
		return dict;
	}
	return nil;
}

- (NSDictionary *) sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData 
{
	NSMutableURLRequest *requestM = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:reqURl] 
																												 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
																										 timeoutInterval:60.0]; 
	[requestM setHTTPMethod:@"POST"]; 
	
	[requestM addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
	
	CFUUIDRef uuid = CFUUIDCreate(nil);
	NSString *uuidString = [(NSString*)CFUUIDCreateString(nil, uuid) autorelease];
	CFRelease(uuid);
	NSString *stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@",uuidString];
	NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
	
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data;  boundary=%@", stringBoundary];
	
	[requestM setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *body = [NSMutableData data];
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageData];        
	[body appendData:[[NSString stringWithFormat:@"%@",endItemBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[requestM setHTTPBody:body];
	
	NSData *responseData = [NSURLConnection sendSynchronousRequest:requestM returningResponse:nil error:nil];
	NSDictionary *dict;
	if(responseData)
	{
		dict = [[JSONDecoder decoder] parseJSONData:responseData];
#ifdef _SHKDebugShowLogs		
		NSString *errorMsg = [[dict objectForKey:@"error"] objectForKey:@"error_msg"];
#endif		
		SHKLog(@"Server response: %@ \nError: %@", dict, errorMsg);
		
		return dict;
	}
	return nil;
}

- (NSString *)URLEncodedString:(NSString *)str
{
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																																				 (CFStringRef)str,
																																				 NULL,
																																				 CFSTR("!*'();:@&=+$,/?%#[]"),
																																				 kCFStringEncodingUTF8);
	[result autorelease];
	return result;
}

@end
