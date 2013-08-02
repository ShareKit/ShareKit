//
//  SHKPlurk.m
//  ShareKit
//
//  Created by Polydice on 2/12/12.
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

#import "SHKPlurk.h"
#import "SharersCommonHeaders.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

NSString * const kSHKPlurkUserInfo = @"kSHKPlurkUserInfo";
NSString * const SHKPlurkQualifierKey = @"qualifier";
NSString * const SHKPlurkPrivateKey = @"limited_to";

@interface SHKPlurk ()

@property BOOL imageUploaded;
@property BOOL isLoadingUserInfo;
@property (strong, nonatomic) id getUserInfoObserver;

@end

@implementation SHKPlurk

- (id)init
{
	if (self = [super init])
	{
		// OAUTH
		self.consumerKey = SHKCONFIG(plurkAppKey);
		self.secretKey = SHKCONFIG(plurkAppSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(plurkCallbackURL)];// HOW-TO: In your Plurk application settings, use the "Callback URL" field.  If you do not have this field in the settings, set your application type to 'Browser'.
    
		// You do not need to edit these, they are the same for everyone
        self.authorizeURL = [NSURL URLWithString:@"http://www.plurk.com/m/authorize"];
        self.requestURL = [NSURL URLWithString:@"http://www.plurk.com/OAuth/request_token"];
        self.accessURL = [NSURL URLWithString:@"http://www.plurk.com/OAuth/access_token"];
	}
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Plurk");
}

+ (BOOL)canShareURL
{
	return YES;
}

- (BOOL)requiresShortenedURL {
    
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

+ (BOOL)canGetUserInfo {
    
    return YES;
}

+ (BOOL)canAutoShare
{
	return NO;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{
	[super promptAuthorization];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
  [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}

+ (void)logout {
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKPlurkUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
	[super logout];
}


#pragma mark -
#pragma mark Share Form
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    if (self.item.shareType == SHKShareTypeUserInfo) return nil;
    
    //we need username to present share sheet. After download will try to present again.
    NSString *username = [self username];
    if (!username) {
        
        SHKPlurk *infoSharer = [SHKPlurk getUserInfo];
        [[SHK currentHelper] keepSharerReference:self]; //so that the sharer still exists aftern userInfo download, reference removed in callback
        __weak typeof(self) weakSelf = self;
        self.getUserInfoObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SHKSendDidFinishNotification
                                                                                      object:infoSharer
                                                                                       queue:[NSOperationQueue mainQueue]
                                                                                  usingBlock:^(NSNotification *notification) {
                                                                                      
                                                                                      weakSelf.isLoadingUserInfo = NO;
                                                                                      [weakSelf show];
                                                                                      [[SHK currentHelper] removeSharerReference:self];
                                                                                      
                                                                                      [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.getUserInfoObserver];
                                                                                      weakSelf.getUserInfoObserver = nil;
                                                                                      
                                                                                  }];

        self.isLoadingUserInfo = YES;
        return nil; //means continue silently. In send method if isLoadingUserInfo escapes without sending anything.
    }
    
    if (self.item.shareType == SHKShareTypeURL)
	{
        [self.item setCustomValue:[NSString stringWithFormat:@"%@ (%@)", [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.item.title] forKey:@"status"];
	}
    
	else if (self.item.shareType == SHKShareTypeImage)
	{
		if (!self.imageUploaded) return nil; //this means we continue to send silently
	}
    
	else if (self.item.shareType == SHKShareTypeText)
	{
		[self.item setCustomValue:self.item.text forKey:@"status"];
	}

    NSArray *result = @[[SHKFormFieldOptionPickerSettings label:username
                                                            key:SHKPlurkQualifierKey
                                                           type:SHKFormFieldTypeOptionPicker
                                                          start:nil
                                                    pickerTitle:username
                                                selectedIndexes:[[NSMutableIndexSet alloc] initWithIndex:2]
                                                  displayValues:@[@"loves", @"likes", @"shares", @"gives", @"hates", @"wants", @"has", @"will", @"asks", @"wishes", @"was", @"feels", @"thinks", @"says", @"is", @"freestyle", @"hopes", @"needs", @"wonders"]
                                                     saveValues:nil
                                                  allowMultiple:NO
                                                   fetchFromWeb:NO
                                                       provider:nil],
                        
                        [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Comment")
                                                         key:@"status"
                                                        type:SHKFormFieldTypeTextLarge
                                                       start:[self.item customValueForKey:@"status"]
                                               maxTextLength:210
                                                       image:self.item.image
                                             imageTextLength:0
                                                        link:self.item.URL
                                                        file:self.item.file
                                              allowEmptySend:NO
                                                      select:YES],
                        
                        [SHKFormFieldSettings label:SHKLocalizedString(@"Private")
                                                key:SHKPlurkPrivateKey
                                               type:SHKFormFieldTypeSwitch
                                              start:SHKFormFieldSwitchOff]];
    return result;
}

- (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKPlurkUserInfo];
    NSString *result = userInfo[@"nick_name"];
    return result;
}

 #pragma mark -

- (void)uploadImage
{
	if (!self.quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Uploading Image...")];
  
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.plurk.com/APP/Timeline/uploadPicture"]
                                                                  consumer:consumer
                                                                     token:accessToken
                                                                     realm:nil
                                                         signatureProvider:nil];
	[oRequest setHTTPMethod:@"POST"];
  
	NSData *imageData = UIImageJPEGRepresentation(self.item.image, 1);
    [oRequest attachFileWithParameterName:@"image" filename:@"shk.jpg" contentType:@"image/jpeg" data:imageData];
  
	// Start the request
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                        delegate:self
                                                                               didFinishSelector:@selector(uploadImageTicket:didFinishWithData:)
                                                                                 didFailSelector:@selector(uploadImageTicket:didFailWithError:)];
	[fetcher start];
}

- (void)uploadImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	[[SHKActivityIndicator currentIndicator] hide];
  
  if (SHKDebugShowLogs) {
    SHKLog(@"Plurk Upload Picture Status Code: %d", [ticket.response statusCode]);
    SHKLog(@"Plurk Upload Picture Error: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
  }
  
	if (ticket.didSucceed) {
		// Finished uploading Image, now need to posh the message and url in twitter
        NSError *error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
		if ([response objectForKey:@"full"]) {
			NSString *urlString = [response objectForKey:@"full"];
			[self.item setCustomValue:[NSString stringWithFormat:@"%@ %@", self.item.title, urlString] forKey:@"status"];
            self.imageUploaded = YES;
			[self show];
		} else {
			[self alertUploadImageWithError:nil];
		}
	} else {
		[self alertUploadImageWithError:nil];
	}
}

- (void)uploadImageTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
	[[SHKActivityIndicator currentIndicator] hide];
  
	[self alertUploadImageWithError:error];
}


- (void)alertUploadImageWithError:(NSError *)error
{
	[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Request Error")
                               message:SHKLocalizedString(@"There was an error while sharing")
                              delegate:nil
                     cancelButtonTitle:SHKLocalizedString(@"Continue")
                     otherButtonTitles:nil] show];
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
	if (self.isLoadingUserInfo) return NO; //wait for userInfo downloaded callback, will show again
    
    if (self.item.shareType == SHKShareTypeUserInfo) self.quiet = YES;
    
    if (![self validateItem]) return NO;
  
    if (self.item.shareType == SHKShareTypeImage && !self.imageUploaded) {
        [self uploadImage];
    } else {
        [self sendStatus];
		[self sendDidStart];
    }
    return YES;
}

- (void)sendStatus
{
	OAMutableURLRequest *oRequest;
    
    if (self.item.shareType == SHKShareTypeUserInfo) {
        oRequest = [[OAMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"http://www.plurk.com/APP/Users/currUser"]
                                                   consumer:consumer
                                                      token:accessToken
                                                      realm:nil
                                          signatureProvider:nil];
        [oRequest setHTTPMethod:@"POST"];
    } else {
    
        oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.plurk.com/APP/Timeline/plurkAdd"]
                                                   consumer:consumer
                                                      token:accessToken
                                                      realm:nil
                                          signatureProvider:nil];
        
        [oRequest setHTTPMethod:@"POST"];
        
        OARequestParameter *qualifierParam = [[OARequestParameter alloc] initWithName:@"qualifier"
                                                                                value:[self.item customValueForKey:SHKPlurkQualifierKey]];
        OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"content"
                                                                             value:[self.item customValueForKey:@"status"]];
        NSMutableArray *params = [@[qualifierParam, statusParam] mutableCopy];
        BOOL isPrivate = [[self.item customValueForKey:SHKPlurkPrivateKey] boolValue];
        if (isPrivate) {
            OARequestParameter *privateParam = [[OARequestParameter alloc] initWithName:SHKPlurkPrivateKey value:@"[0]"];
            [params addObject:privateParam];
        }
        
        [oRequest setParameters:params];
    }
  
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                        delegate:self
                                                                               didFinishSelector:@selector(sendStatusTicket:didFinishWithData:)
                                                                                 didFailSelector:@selector(sendStatusTicket:didFailWithError:)];	
  
	[fetcher start];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed) {
        
        if (self.item.shareType == SHKShareTypeUserInfo) {
            NSError *error;
            NSMutableDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                SHKLog(@"Error when parsing json user info request:%@", [error description]);
            }
            
            [userInfo convertNSNullsToEmptyStrings];
            [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKPlurkUserInfo];
        }
        
        [self sendDidFinish];
    
    } else {
        
        [[SHK currentHelper] removeSharerReference:self]; //to be sure, see shareFormFieldsForType
        NSError *error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
		if (SHKDebugShowLogs)
			SHKLog(@"Plurk Send Status Error: %@", [response description]);
    
		// in case our makeshift parsing does not yield an error message
		NSString *errorMessage = [response objectForKey:@"error_text"];
    
		// this is the error message for revoked access
		if ([errorMessage isEqualToString:@"40106:invalid access token"])
		{
			[self shouldReloginWithPendingAction:SHKPendingSend];
		}
		else
		{
			[self sendShowSimpleErrorAlert];
		}
	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

@end