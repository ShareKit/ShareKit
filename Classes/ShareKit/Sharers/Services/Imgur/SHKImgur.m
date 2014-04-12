//  Created by Andrew Shu on 03/20/2014.

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

#import "SHKImgur.h"

#import "NSDictionary+Recursive.h"
#import "SharersCommonHeaders.h"
#import "SHKOAuth2View.h"
#import "SHKSession.h"
#import "SHKRequest.h"

#define kSHKImgurUserInfo @"kSHKImgurUserInfo"
#define kSHKImgurSuppressUnreadTermsError @"0"

@interface SHKImgur ()

@property (copy, nonatomic) NSString *accessTokenString;
@property (copy, nonatomic) NSString *accessTokenType;
@property (copy, nonatomic) NSString *refreshTokenString;
@property (copy, nonatomic) NSDate *expirationDate;

@end

@implementation SHKImgur

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Imgur");
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file
{
    NSString *mimeType = [file mimeType];
    return [mimeType hasPrefix:@"image/"];
}

+ (BOOL)requiresAuthentication
{
	BOOL result = ![SHKCONFIG(imgurAnonymousUploads) boolValue];
    return result;
}

#pragma mark -
#pragma mark Authentication

- (id)init
{
    self = [super init];
    
	if (self)
	{
		self.consumerKey = SHKCONFIG(imgurClientID);
		self.secretKey = SHKCONFIG(imgurClientSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(imgurCallbackURL)];
		
		// -- //
		
	    self.requestURL   = nil;
	    self.authorizeURL = [NSURL URLWithString:@"https://api.imgur.com/oauth2/authorize"];
	    self.accessURL    = [NSURL URLWithString:@"https://api.imgur.com/oauth2/token"];
	}
	return self;
}

#pragma mark - 
#pragma mark OAuth2 overrides

- (BOOL)isAuthorized {
    
    if ([SHKCONFIG(imgurAnonymousUploads) boolValue]) {
        return YES;
    } else {
        return [self restoreAccessToken];
    }
}

- (void)tokenRequest {
    // OAuth 2.0 does not have this step.
    // Skip to Token Authorize step.
    [self tokenAuthorize];
}

- (void)tokenAuthorize
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?response_type=token&client_id=%@", [self.authorizeURL absoluteString], self.consumerKey]];
	
	SHKOAuth2View *auth = [[SHKOAuth2View alloc] initWithURL:url delegate:self];
	[[SHK currentHelper] showViewController:auth];
}

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error {
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
    if (success) {

        [self storeAccessToken:queryParams];
        [self tryPendingAction];
        
    } else {
        [[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Access Error")
                                    message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
                                   delegate:nil
                          cancelButtonTitle:SHKLocalizedString(@"Close")
                          otherButtonTitles:nil] show];
    }
    [self authDidFinish:success];
}

- (void)storeAccessToken:(NSMutableDictionary *)queryParams
{
    self.accessTokenString  = [queryParams objectForKey:@"access_token"];
    self.accessTokenType    = [queryParams objectForKey:@"token_type"];
    self.refreshTokenString = [queryParams objectForKey:@"refresh_token"];
    self.expirationDate     = [NSDate dateWithTimeIntervalSinceNow:[[queryParams objectForKey:@"expires_in"] doubleValue]];
    [[self class] setUsername:[queryParams objectForKey:@"account_username"]];
    
	[SHK setAuthValue:self.accessTokenString
               forKey:@"accessToken"
            forSharer:[self sharerId]];
	
	[SHK setAuthValue:self.accessTokenType
               forKey:@"accessTokenType"
            forSharer:[self sharerId]];
	
	[SHK setAuthValue:self.refreshTokenString
               forKey:@"refreshToken"
			forSharer:[self sharerId]];
	
	[SHK setAuthValue:[@([self.expirationDate timeIntervalSinceReferenceDate]) stringValue]
			   forKey:@"expirationDate"
			forSharer:[self sharerId]];
}

+ (void)deleteStoredAccessToken
{
	NSString *sharerId = [self sharerId];
	
	[SHK removeAuthValueForKey:@"accessToken" forSharer:sharerId];
	[SHK removeAuthValueForKey:@"accessTokenType" forSharer:sharerId];
	[SHK removeAuthValueForKey:@"refreshToken" forSharer:sharerId];
	[SHK removeAuthValueForKey:@"expirationDate" forSharer:sharerId];
}

//if the sharer can get user info (and it should!) override these convenience methods too. Replace example implementation with the one specific for your sharer.
+ (NSString *)username {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKImgurUserInfo];
    NSString *result = [userInfo findRecursivelyValueForKey:@"username"];
    return result;
}

+ (void)setUsername:(NSString *)username {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *userInfo = [[defaults dictionaryForKey:kSHKImgurUserInfo] mutableCopy];
    if (!userInfo) {
        userInfo = [NSMutableDictionary dictionary];
    }
    [userInfo setObject:username forKey:@"username"];
    [defaults setObject:[userInfo copy] forKey:kSHKImgurUserInfo];
}

+ (void)logout {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKImgurUserInfo];
    [super logout];
}

- (BOOL)restoreAccessToken {
    
    NSString *sharerId = [self sharerId];
    
    self.accessTokenString  = [SHK getAuthValueForKey:@"accessToken" forSharer:sharerId];
    self.accessTokenType    = [SHK getAuthValueForKey:@"accessTokenType" forSharer:sharerId];
    self.refreshTokenString = [SHK getAuthValueForKey:@"refreshToken" forSharer:sharerId];
    self.expirationDate     = [NSDate dateWithTimeIntervalSinceReferenceDate:[[SHK getAuthValueForKey:@"expirationDate" forSharer:sharerId] doubleValue]];
    
    BOOL tokenExists = self.accessTokenString && ![@"" isEqualToString:self.accessTokenString];
    
    BOOL expired = [self.expirationDate compare:[NSDate date]] == NSOrderedAscending;
    if (expired && tokenExists) {
        [self refreshToken];
    }
    
    return tokenExists;
}

- (void)refreshToken {
    
    NSString *params = [[NSString alloc] initWithFormat:@"&refresh_token=%@&client_id=%@&client_secret=%@&grant_type=refresh_token",
    self.refreshTokenString,
    self.consumerKey,
    self.secretKey];
    
    [SHKRequest startWithURL:self.accessURL params:params method:@"POST" completion:^(SHKRequest *request) {
        
        NSError *error;
        id response = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
        
        if (request.success) {
            [self storeAccessToken:response];
            [self tryPendingAction];
        
        } else {
            [self promptAuthorization];
            SHKLog(@"SHKImgur refreshToken failed with response:%@", [response description]);
        }
    }];
}

#pragma mark -
#pragma mark Share Form

// If your action has options or additional information it needs to get from the user,
// use this to create the form that is presented to user upon sharing. You can even set validationBlock to validate user's input for any field setting)
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    // See http://getsharekit.com/docs/#forms for documentation on creating forms
    
    if (type == SHKShareTypeImage || type == SHKShareTypeFile) {
        
        NSMutableArray *fields = [@[[SHKFormFieldSettings label:@"Title"
                                                           key:@"title"
                                                          type:SHKFormFieldTypeText
                                                         start:self.item.title],
                                   [SHKFormFieldSettings label:@"Description"
                                                           key:@"description"
                                                          type:SHKFormFieldTypeText
                                                         start:self.item.text]] mutableCopy];
        
        if (![SHKCONFIG(imgurAnonymousUploads) boolValue]) {
            
            [fields addObject: [SHKFormFieldSettings label:SHKLocalizedString(@"Imgur Public Gallery")
                                                       key:@"is_gallery"
                                                      type:SHKFormFieldTypeSwitch
                                                     start:SHKFormFieldSwitchOff]];
        }
        return fields;
    }
    return nil;
}

#pragma mark -
#pragma mark Implementation

- (BOOL)send
{
	if (![self validateItem])
		return NO;
    
    switch (self.item.shareType) {
        case SHKShareTypeImage:
        case SHKShareTypeFile:
            [self uploadPhoto];
            break;
        default:
            break;
    }
    
    [self sendDidStart];
    return YES;
}

- (void)uploadPhoto {

    NSMutableURLRequest *oRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/upload"]];
    [oRequest setHTTPMethod:@"POST"];
    
    if ([SHKCONFIG(imgurAnonymousUploads) boolValue]) {
        
        // Imgur Client-ID header, anonymous upload
        [oRequest addValue:[NSString stringWithFormat:@"Client-ID %@", SHKCONFIG(imgurClientID)] forHTTPHeaderField:@"Authorization"];
        
    } else {
        
        // OAuth 2.0 header
        [oRequest addValue:[NSString stringWithFormat:@"Bearer %@", self.accessTokenString] forHTTPHeaderField:@"Authorization"];
    }
    
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:2];
    if ([self.item.title length] > 0) {
        [params addObject:[[OARequestParameter alloc] initWithName:@"title" value:self.item.title]];
    }
    if ([[self.item customValueForKey:@"description"] length] > 0) {
        [params addObject:[[OARequestParameter alloc] initWithName:@"description" value:[self.item customValueForKey:@"description"]]];
    }
    [oRequest setParameters:params];
    
    if (self.item.shareType == SHKShareTypeImage) {
        
        [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:1];
    }
    
    [oRequest attachFile:self.item.file withParameterName:@"image"];
    
    BOOL canUseNSURLSession = NSClassFromString(@"NSURLSession") != nil;
    if (canUseNSURLSession) {
        
        __weak typeof(self) weakSelf = self;
        self.networkSession = [SHKSession startSessionWithRequest:oRequest delegate:self completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (error.code == -999) {
                
                [weakSelf sendDidCancel];
                
            } else if (error) {
                
                SHKLog(@"upload photo did fail with error:%@", [error description]);
                [self sendDidFailWithError:error];
                
            } else if ([(NSHTTPURLResponse *)response statusCode] == 403) { //invalid token (user revoked access, or expired token)
                
                self.pendingAction = SHKPendingSend;
                [self refreshToken];
            
            } else {
                
                BOOL success = [(NSHTTPURLResponse *)response statusCode] < 400;
                [weakSelf uploadPhotoDidFinishWithData:data success:success];
            }
            [[SHK currentHelper] removeSharerReference:weakSelf];
        }];
        [[SHK currentHelper] keepSharerReference:self];
        
    } else {
        
        [SHKRequest startWithRequest:oRequest completion:^(SHKRequest *request) {
            [self uploadPhotoDidFinishWithData:request.data success:request.success];
        }];
    }
}

- (void)uploadPhotoDidFinishWithData:(NSData *)data success:(BOOL)success {

    NSError *error;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (success) {
        
        NSString *imageID = [response findRecursivelyValueForKey:@"id"];
        
        if (imageID) {
            
            [self sendDidFinishWithResponse:response];
            
            if ([self.item customBoolForSwitchKey:@"is_gallery"]) {
                [self submitImageToGallery:imageID];
            }
            
        } else {
            
            NSString *errorMessage = [response findRecursivelyValueForKey:@"error"];
            [self sendDidFailWithError:[SHK error:errorMessage]];
        }

    } else {
        
        [self sendShowSimpleErrorAlert];
        SHKLog(@"Imgur upload failed with error:%@", [response findRecursivelyValueForKey:@"error"]);
    }
}

- (void)submitImageToGallery:(NSString *)imageID {
    
    NSString *URLString = [NSString stringWithFormat:@"https://api.imgur.com/3/gallery/image/%@", imageID];
    NSString *params = [NSString stringWithFormat:@"&title=%@&terms=%@", SHKEncode(self.item.title), kSHKImgurSuppressUnreadTermsError];
    SHKRequest *galleryRequest = [[SHKRequest alloc] initWithURL:[NSURL URLWithString:URLString] params:params method:@"POST" completion:^(SHKRequest *request){
        
        if (request.success) {
            SHKLog(@"image was submitted to Imgur public gallery");
        } else {
            SHKLog(@"imgur failed to move uploaded image to public gallery with error:%@", [[NSString alloc] initWithData:request.data encoding:NSUTF8StringEncoding]);
        }
    }];
    
    NSString *bearerHeader = [NSString stringWithFormat:@"Bearer %@", self.accessTokenString];
    galleryRequest.headerFields = @{@"Authorization": bearerHeader};
    [galleryRequest start];
}

@end
