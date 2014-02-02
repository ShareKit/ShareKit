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
#import "SHKVkontakteOAuthView.h"
#import "SHKVKontakteRequest.h"
#import "SharersCommonHeaders.h"
#import "NSHTTPCookieStorage+DeleteForURL.h"

@interface SHKVkontakte()

@property BOOL isCaptcha;
@property (nonatomic, strong) NSString *accessUserId;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSDate *expirationDate;

- (void)getAccessCode;

- (void)getUserInfo;
- (void)getCaptcha;
- (void)sendRequest:(NSString *)reqURl withCaptcha:(BOOL)captcha;
- (void) sendRequest:(NSString *)reqURl withCaptcha:(BOOL)captcha completion:(RequestCallback)completion;
- (void) sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData;
- (void)sendTextAndLink;
- (void)sendImageAction;
- (void)sendText;
- (NSString *)URLEncodedString:(NSString *)str;

@end

@implementation SHKVkontakte

+ (void)flushAccessToken 
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:kSHKVkonakteUserId];
  [defaults removeObjectForKey:kSHKVkontakteAccessTokenKey];
  [defaults removeObjectForKey:kSHKVkontakteExpiryDateKey];
  [defaults removeObjectForKey:kSHKVkontakteAccessCodeKey];
    [defaults removeObjectForKey:kSHKVkonakteUserInfo];
  [defaults synchronize];
}


#pragma mark - Properties -

-(NSString*)accessToken
{
    if (!_accessToken)
    {
        _accessToken=[[NSUserDefaults standardUserDefaults] objectForKey:kSHKVkontakteAccessTokenKey];
    }
    return _accessToken;
}

-(NSString*)accessUserId
{
    if (!_accessUserId)
    {
        _accessUserId=[[NSUserDefaults standardUserDefaults] objectForKey:kSHKVkonakteUserId];
    }
    return _accessUserId;
}

-(NSDate*)expirationDate
{
    if (!_expirationDate)
    {
        _expirationDate=[[NSUserDefaults standardUserDefaults] objectForKey:kSHKVkontakteExpiryDateKey];
    }
    return _expirationDate;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Vkontakte");
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
	return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file {
    return YES;
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
	
	[[SHK currentHelper] showViewController:self];
}


- (void)getAccessCode
{
    //we can request AccessCode only if we already authorized
    if ([self isAuthorized])
    {
        NSString *appID = SHKCONFIG(vkontakteAppId);
        NSString *reqURl = [NSString stringWithFormat:@"http://api.vk.com/oauth/authorize?client_id=%@&scope=wall,photos&redirect_uri=http://api.vk.com/blank.html&display=touch&response_type=code", appID];
        [SHKRequest startWithURL:[NSURL URLWithString:reqURl]
                          params:nil
                          method:@"GET"
                      completion:^(SHKRequest *request) {
                          
                          if (request.success)
                          {
                              NSString *accessCode = [SHKVkontakteOAuthView stringBetweenString:@"code="
                                                                                      andString:@"&"
                                                                                    innerString:request.response.URL.absoluteString];
                              
                              if(accessCode)
                              {
                                  [[NSUserDefaults standardUserDefaults] setObject:accessCode forKey:kSHKVkontakteAccessCodeKey];
                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                  [self authDidFinish: YES];
                              } else
                              {
                                  [self authDidFinish: NO];
                              }
                          } else
                          {
                              [self authDidFinish: NO];
                          }
                      }];
    } else
    {
        [self authDidFinish: NO];
    }
}

- (void)getUserInfo
{
    self.quiet = YES;
    if ([self isAuthorized])
    {
        NSString *reqURl = [NSString stringWithFormat:@"https://api.vk.com/method/users.get?uids=%@&fields=uid,first_name,last_name,nickname,sex,bdate,city,country,timezone,photo,photo_medium,photo_big,photo_rec&access_token=%@", self.accessUserId,self.accessToken];
        [SHKRequest startWithURL:[NSURL URLWithString:reqURl]
                          params:nil
                          method:@"GET"
                      completion:^(SHKRequest *request) {
                          
                          if (request.success)
                          {
                              // convert to JSON
                              NSError *error = nil;
                              NSDictionary *res = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
                              NSArray *response=[res objectForKey:@"response"] ? [res objectForKey:@"response"] : nil;
                              NSArray *userInfo=response.count ? [response objectAtIndex:0] : nil;
                              
                              if (userInfo)
                              {
                                  [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKVkonakteUserInfo];
                                  [[NSUserDefaults standardUserDefaults] synchronize];
                                  [self sendDidFinish];
                              } else
                              {
                                  [self sendDidFailWithError:nil];
                              }
                              
                          } else
                          {
                              [self sendDidFailWithError:nil];
                          }
                      }];
    } else
    {
        [self sendDidFailWithError:nil];
    }
}

#pragma mark -

- (void) authComplete 
{
    [self getAccessCode];
    
    //[self authDidFinish: YES];
	if (self.item) 
		[self share];
}

+ (void)logout
{
    [NSHTTPCookieStorage deleteCookiesForURL:[NSURL URLWithString:@"http://api.vk.com/oauth/authorize"]];
    [self flushAccessToken];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKVkonakteUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKVkonakteUserInfo];
    if (userInfo) {
        NSString *result = [[NSString alloc] initWithFormat:@"%@ %@", userInfo[@"first_name"], userInfo[@"last_name"]];
        return result;
    } else {
        return nil;
    }
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{			
 	if (![self validateItem])
		return NO;
	
	//[self setQuiet:NO];
    
    switch (self.item.shareType) {
        case SHKShareTypeURL:
            [self sendTextAndLink];
            break;
        case SHKShareTypeText:
            [self sendText];
            break;
        case SHKShareTypeImage:
            [self sendImageAction];
            break;
        case SHKShareTypeUserInfo:
            [self getUserInfo];
            break;
        case SHKShareTypeFile:
            [self sendFileAction];
            break;
        default:
            return NO;
    }
    
    [self sendDidStart];
    return YES;
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
            text = self.item.title;
            key = @"title";
            break;
        default:
            return nil;
    }
        
    SHKFormFieldLargeTextSettings *commentField = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Comment")
                                                                                   key:key
                                                                                 start:text
                                                                                  item:self.item];
    commentField.select = YES;
    commentField.validationBlock = ^ (SHKFormFieldLargeTextSettings *formFieldSettings) {
        
        BOOL result = formFieldSettings.valueToSave > 0;
        return result;
    };
    
    return @[commentField];
}

///////////////////////////////////////////////////////////////////////////
//
#pragma mark - sendImageAction -
//
///////////////////////////////////////////////////////////////////////////



//Private
- (void)sendImageAction
{
    
	NSString *getWallUploadServer = [NSString stringWithFormat:@"https://api.vk.com/method/photos.getWallUploadServer?owner_id=%@&access_token=%@", self.accessUserId, self.accessToken];
    [self sendRequest:getWallUploadServer withCaptcha:NO completion:^(SHKRequest *request) {
        
        if ([self isRequestFinishedWithoutError:request])
        {
            // convert to JSON
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
            NSString *upload_url = [[responseDict objectForKey:@"response"] objectForKey:@"upload_url"];
            if (upload_url)
            {
                UIImage *image = self.item.image;
                NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
                //processing to next request
                [self sendPOSTRequest:upload_url withImageData:imageData];
                return;
            }
        }
    }];
}

- (void)sendFileAction
{
	NSString *getWallUploadServer = [NSString stringWithFormat:@"https://api.vk.com/method/docs.getUploadServer?owner_id=%@&access_token=%@", self.accessUserId, self.accessToken];
    [self sendRequest:getWallUploadServer withCaptcha:NO completion: ^(SHKRequest *request) {
        
        if ([self isRequestFinishedWithoutError:request])
        {
            // convert to JSON
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
            NSString *upload_url = [[responseDict objectForKey:@"response"] objectForKey:@"upload_url"];
            if (upload_url)
            {
                [self sendPOSTRequest:upload_url withFileData:self.item.file.data fileName:self.item.file.filename mime:self.item.file.mimeType];
                return;
            }
        }
    }];
}

///////////////////////////////////////////////////////////////////////////
//
#pragma mark -
//
///////////////////////////////////////////////////////////////////////////




- (void) getCaptcha 
{
	NSString *captcha_img = [[NSUserDefaults standardUserDefaults] objectForKey:@"captcha_img"];
	UIAlertView *myAlertView = [[UIAlertView alloc] initWithTitle:@"Введите код:\n\n\n\n\n"
																												message:@"\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(12.0, 45.0, 130.0, 50.0)];
	imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:captcha_img]]];
	[myAlertView addSubview:imageView];
	
	UITextField *myTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 110.0, 260.0, 25.0)];
	[myTextField setBackgroundColor:[UIColor whiteColor]];
	
	myTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	myTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	myTextField.tag = 33;
	
	[myAlertView addSubview:myTextField];
	[myAlertView show];
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(self.isCaptcha && buttonIndex == 1)
	{
		self.isCaptcha = NO;
		
		UITextField *myTextField = (UITextField *)[actionSheet viewWithTag:33];
		[[NSUserDefaults standardUserDefaults] setObject:myTextField.text forKey:@"captcha_user"];
		
		NSString *requestM = [[NSUserDefaults standardUserDefaults] objectForKey:@"request"];

		[self sendRequest:requestM withCaptcha:YES];
	}
}


- (void) sendText
{		
	NSString *sendTextMessage = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@", self.accessUserId, self.accessToken, [self URLEncodedString:self.item.text]];
	
	[self sendRequest:sendTextMessage withCaptcha:NO];
}


- (void) sendTextAndLink
{	
	NSString *sendTextAndLinkMessage = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@&attachment=%@", self.accessUserId, self.accessToken, [self URLEncodedString:self.item.text]?[self URLEncodedString:self.item.text]:[self.item.URL absoluteString], [self.item.URL absoluteString]];
	
	[self sendRequest:sendTextAndLinkMessage withCaptcha:NO];
}




///////////////////////////////////////////////////////////////////////////
//
#pragma mark - Send Request -
//
///////////////////////////////////////////////////////////////////////////

- (void) sendRequest:(NSString *)reqURl withCaptcha:(BOOL)captcha
{
    [self sendRequest:reqURl withCaptcha:captcha completion:^(SHKRequest *request) {
        
        if ([self isRequestFinishedWithoutError:request])
        {
            NSError *error = nil;
            NSDictionary *res = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
            NSString *errorMsg = [[res objectForKey:@"error"] objectForKey:@"error_msg"];
            
            if([errorMsg isEqualToString:@"Captcha needed"])
            {
                self.isCaptcha = YES;
                
                NSString *captcha_sid = [[res objectForKey:@"error"] objectForKey:@"captcha_sid"];
                NSString *captcha_img = [[res objectForKey:@"error"] objectForKey:@"captcha_img"];
                [[NSUserDefaults standardUserDefaults] setObject:captcha_img forKey:@"captcha_img"];
                [[NSUserDefaults standardUserDefaults] setObject:captcha_sid forKey:@"captcha_sid"];
                
                [[NSUserDefaults standardUserDefaults] setObject:request.url forKey:@"request"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self getCaptcha];
            } else
            {
                [self sendDidFinish];
            }
        }
    }];
}

- (void) sendRequest:(NSString *)reqURl withCaptcha:(BOOL)captcha completion:(RequestCallback)completion
{
	if(captcha == YES)
	{
		NSString *captcha_sid = [[NSUserDefaults standardUserDefaults] objectForKey:@"captcha_sid"];
		NSString *captcha_user = [[NSUserDefaults standardUserDefaults] objectForKey:@"captcha_user"];
        
		reqURl = [reqURl stringByAppendingFormat:@"&captcha_sid=%@&captcha_key=%@", captcha_sid, [self URLEncodedString: captcha_user]];
	}
    
    [SHKRequest startWithURL:[NSURL URLWithString:reqURl] params:nil method:@"GET" completion:completion];
}

- (BOOL)isRequestFinishedWithoutError:(SHKRequest *)aRequest
{
    if (aRequest.success)
    {
        // convert to JSON
        NSError *error = nil;
        NSDictionary *res = [NSJSONSerialization JSONObjectWithData:aRequest.data options:NSJSONReadingMutableContainers error:&error];

        if (res)
        {
            NSString *errorMsg = [[res objectForKey:@"error"] objectForKey:@"error_msg"];
            NSNumber *errorCode=[[res objectForKey:@"error"] objectForKey:@"error_code"];
            
            if (!errorMsg)
            {
                return YES;
            } else
            if([errorMsg isEqualToString:@"Captcha needed"])
            {
                return YES;
            } else
            {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          errorMsg, NSLocalizedDescriptionKey,
                                          nil];
                
                [self sendDidFailWithError:[NSError errorWithDomain:errorMsg code:[errorCode integerValue] userInfo:userInfo]];
                return NO;
            }
        }
    }
    
    [self sendDidFailWithError:nil];
    return NO;
}

///////////////////////////////////////////////////////////////////////////
//
#pragma mark - Post Request With ImageData or FileData - 
//
///////////////////////////////////////////////////////////////////////////



- (void) sendPOSTRequest:(NSString *)reqURl withImageData:(NSData *)imageData
{
    //creating headers
	CFUUIDRef uuid = CFUUIDCreate(nil);
	NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuid));
	CFRelease(uuid);
    
	NSString *stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@",uuidString];
	NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data;  boundary=%@", stringBoundary];

    //creating body
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageData];
	[body appendData:[[NSString stringWithFormat:@"%@",endItemBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    SHKVKontakteRequest *request = [[SHKVKontakteRequest alloc] initWithURL:[NSURL URLWithString:reqURl]
                                                                  paramsData:[NSData dataWithData:body]
                                                                      method:@"POST"
                                                                  completion:[self POSTRequestCompletionBlock]];
    
    //setting headers
    request.headerFields=[NSDictionary dictionaryWithObjectsAndKeys:
                          @"8bit",         @"Content-Transfer-Encoding",
                          contentType,     @"Content-Type",
                          nil];
    
    [request start];
}


- (void) sendPOSTRequest:(NSString *)reqURl withFileData:(NSData *)fileData fileName:(NSString*)filename mime:(NSString*)mime
{
    //creating headers
	CFUUIDRef uuid = CFUUIDCreate(nil);
	NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuid));
	CFRelease(uuid);
    
	NSString *stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@",uuidString];
	NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data;  boundary=%@", stringBoundary];
    
    //creating body
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mime] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:fileData];
	[body appendData:[[NSString stringWithFormat:@"%@",endItemBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    SHKVKontakteRequest *request = [[SHKVKontakteRequest alloc] initWithURL:[NSURL URLWithString:reqURl]
                                                                  paramsData:[NSData dataWithData:body]
                                                                      method:@"POST"
                                                                  completion:[self POSTRequestCompletionBlock]];
    
    //setting headers
    request.headerFields=[NSDictionary dictionaryWithObjectsAndKeys:
                          @"8bit",         @"Content-Transfer-Encoding",
                          contentType,     @"Content-Type",
                          nil];
    
    [request start];
}


- (RequestCallback)POSTRequestCompletionBlock
{
    RequestCallback result = ^(SHKRequest *request) {
        
        if ([self isRequestFinishedWithoutError:request])
        {
            // convert to JSON
            NSError *error = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
            NSString *hash = [responseDict objectForKey:@"hash"];
            NSString *photo = [responseDict objectForKey:@"photo"];
            NSString *server = [responseDict objectForKey:@"server"];
            NSString *file = [responseDict objectForKey:@"file"];
            
            if (hash && photo && server)
            {
                //processing to next request
                NSString *saveWallPhoto = [NSString stringWithFormat:@"https://api.vk.com/method/photos.saveWallPhoto?owner_id=%@&access_token=%@&server=%@&photo=%@&hash=%@", self.accessUserId, self.accessToken ,server, [self URLEncodedString:photo], hash];
                
                [self sendRequest:saveWallPhoto withCaptcha:NO completion:^(SHKRequest *request) {
                    
                    if ([self isRequestFinishedWithoutError:request])
                    {
                        // convert to JSON
                        NSError *error = nil;
                        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
                        NSDictionary *photoDict = [[responseDict objectForKey:@"response"] lastObject];
                        NSString *photoId = [photoDict objectForKey:@"id"];
                        if (photoDict && photoId)
                        {
                            NSString *postToWallLink = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@&attachment=%@", self.accessUserId, self.accessToken, [self URLEncodedString:self.item.title], photoId];
                            
                            //processing to next request
                            [self sendRequest:postToWallLink withCaptcha:NO];
                            return;
                        }
                    }
                }];
            }
            else if (file)
            {
                NSString *saveWallPhoto = [NSString stringWithFormat:@"https://api.vk.com/method/docs.save?owner_id=%@&access_token=%@&file=%@", self.accessUserId, self.accessToken, [self URLEncodedString:file]];
                
                [self sendRequest:saveWallPhoto withCaptcha:NO completion:^(SHKRequest *request) {
                    
                    if ([self isRequestFinishedWithoutError:request])
                    {
                        // convert to JSON
                        NSError *error = nil;
                        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
                        NSDictionary *documentDict = [[responseDict objectForKey:@"response"] lastObject];
                        NSString *ownerId = [documentDict objectForKey:@"owner_id"];
                        NSString *documentId = [documentDict objectForKey:@"did"];
                        if (documentDict && ownerId && documentId)
                        {
                            NSString *attachment = [NSString stringWithFormat:@"doc%@_%@", ownerId, documentId];
                            if (self.item.URL)
                                attachment = [attachment stringByAppendingFormat:@",%@", [self URLEncodedString:[self.item.URL absoluteString]]];
                            NSString *postToWallLink = [NSString stringWithFormat:@"https://api.vk.com/method/wall.post?owner_id=%@&access_token=%@&message=%@&attachment=%@", self.accessUserId, self.accessToken, [self URLEncodedString:self.item.title], attachment];
                            
                            //processing to next request
                            [self sendRequest:postToWallLink withCaptcha:NO];
                            return;
                        }
                    }
                }];
            }
        }
    };
    
    return result;
}

- (NSString *)URLEncodedString:(NSString *)str
{
	NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (CFStringRef)str,
                                                                           NULL,
                                                                           CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8));
	return result;
}

@end
