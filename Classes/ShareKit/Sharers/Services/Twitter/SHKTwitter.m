 //
//  SHKTwitter.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

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

// TODO - SHKTwitter supports offline sharing, however the url cannot be shortened without an internet connection.  Need a graceful workaround for this.

#import "SHKTwitter.h"

#import "SharersCommonHeaders.h"
#import "SHKXMLResponseParser.h"
#import "SHKiOSTwitter.h"
#import "SHKiOS5Twitter.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

#import <Social/Social.h>

#define MAX_TWEET_LENGTH 140
#define MAX_FILE_SIZE 3145728
#define API_CONFIG_PHOTO_SIZE_KEY @"photo_size_limit"
#define CHARS_PER_MEDIA 23
#define API_CONFIG_CHARACTERS_RESERVED_PER_MEDIA @"characters_reserved_per_media"
#define CHARS_PER_URL 23
#define API_CONFIG_CHARACTERS_RESERVED_PER_URL @"short_url_length_https"
#define REVOKED_ACCESS_ERROR_CODE 32

static NSString * const kSHKTwitterUserInfo=@"kSHKTwitterUserInfo";
static NSString * const SHKTwitterAPIConfigurationDataKey = @"SHKTwitterAPIConfigurationDataKey";
static NSString * const SHKTwitterAPIConfigurationSaveDateKey = @"SHKTwitterAPIConfigurationSaveDateKey";

@implementation SHKTwitter

- (id)init
{
	if (self = [super init])
	{	
		// OAUTH		
		self.consumerKey = SHKCONFIG(twitterConsumerKey);		
		self.secretKey = SHKCONFIG(twitterSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(twitterCallbackUrl)];// HOW-TO: In your Twitter application settings, use the "Callback URL" field.  If you do not have this field in the settings, set your application type to 'Browser'.
		
		// XAUTH
		self.xAuth = [SHKCONFIG(twitterUseXAuth) boolValue]?YES:NO;
		
		
		// -- //
		
		
		// You do not need to edit these, they are the same for everyone
		self.authorizeURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
		self.requestURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
		self.accessURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]; 
	}	
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Twitter");
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

+ (BOOL)canShareFile:(SHKFile *)file {
    
    BOOL isUsingPreiOS5Sharing = ![self twitterFrameworkAvailable] && ![self socialFrameworkAvailable];
    BOOL isVideo = [file.mimeType hasPrefix:@"video/"]; //all videos are supported by Yfrog
    BOOL isSupportedImage = [file.mimeType isEqualToString:@"image/png"] || [file.mimeType isEqualToString:@"image/gif"] || [file.mimeType isEqualToString:@"image/jpeg"] || [file.mimeType isEqualToString:@"image/bmp"] || [file.mimeType isEqualToString:@"image/x-windows-bmp"];
    
    if (isUsingPreiOS5Sharing && (isVideo || isSupportedImage)) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Fetch Twitter API configuration

+ (NSUInteger)maxTwitterFileSize {
    
    NSDictionary *twitterAPIConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHKTwitterAPIConfigurationDataKey];
    NSUInteger result = [twitterAPIConfig[API_CONFIG_PHOTO_SIZE_KEY] integerValue];
    if (!result) {
        result = MAX_FILE_SIZE;//if not fetched yet, return last known value. This must be quick in order not to slow share menu creation.
    }
    return result;
}

- (NSUInteger)charsReservedPerMedia {
    
    NSDictionary *twitterAPIConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHKTwitterAPIConfigurationDataKey];
    NSUInteger result = [twitterAPIConfig[API_CONFIG_CHARACTERS_RESERVED_PER_MEDIA] integerValue];
    if (!result) {
        result = CHARS_PER_MEDIA;//if not fetched yet, return last known value.
    }
    return result;
}

- (NSUInteger)charsReservedPerURL {
    
    NSDictionary *twitterAPIConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHKTwitterAPIConfigurationDataKey];
    NSUInteger result = [twitterAPIConfig[API_CONFIG_CHARACTERS_RESERVED_PER_URL] integerValue];
    if (!result) {
        result = CHARS_PER_URL;//if not fetched yet, return last known value.
    }
    return result;
}

- (void)downloadAPIConfiguration {
    
    NSDate *lastFetchDate = [[NSUserDefaults standardUserDefaults] objectForKey:SHKTwitterAPIConfigurationSaveDateKey];
    BOOL isConfigOld = [[NSDate date] compare:[lastFetchDate dateByAddingTimeInterval:24*60*60]] == NSOrderedDescending;
    if (isConfigOld || !lastFetchDate) {
        
            OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/help/configuration.json"]
                                                                            consumer:consumer
                                                                               token:accessToken
                                                                               realm:nil
                                                                   signatureProvider:nil];
            [oRequest setHTTPMethod:@"GET"];
            OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                                  delegate:self
                                                                                         didFinishSelector:@selector(configFetchTicket:didFinishWithData:)
                                                                                           didFailSelector:nil];
            [fetcher start];
        }
}

- (void)configFetchTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    
    if (ticket.didSucceed) {
        
        [self saveData:data defaultsKey:SHKTwitterAPIConfigurationDataKey];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SHKTwitterAPIConfigurationSaveDateKey];
        
    } else {
        
        SHKLog(@"Error when fetching Twitter config:%@", ticket.body);
    }
}

- (void)saveData:(NSData *)data defaultsKey:(NSString *)key {
    
    NSError *error = nil;
    NSMutableDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        SHKLog(@"Error when parsing json %@ request:%@", key, [error description]);
    }
    
    [parsedData convertNSNullsToEmptyStrings];
    [[NSUserDefaults standardUserDefaults] setObject:parsedData forKey:key];
}

#pragma mark -
#pragma mark Commit Share

- (void)share {
	if ([[self class] socialFrameworkAvailable])
	{
		SHKSharer *sharer = [SHKiOSTwitter shareItem:self.item];
		[self setupiOSSharer:sharer];
	}
	else if ([[self class] twitterFrameworkAvailable])
	{
		SHKSharer *sharer = [SHKiOS5Twitter shareItem:self.item];
		[self setupiOSSharer:sharer];
	}
	else
	{
        [super share];
	}
}

- (void)setupiOSSharer:(SHKSharer *)sharer {
    sharer.quiet = self.quiet;
    sharer.shareDelegate = self.shareDelegate;
    [SHKTwitter logout];//to clean credentials - we will not need them anymore
}

#pragma mark -

+ (BOOL)twitterFrameworkAvailable {
	
    if ([SHKCONFIG(forcePreIOS5TwitterAccess) boolValue])
    {
        return NO;
    }
    
	if (NSClassFromString(@"TWTweetComposeViewController")) {
		return YES;
	}
	
	return NO;
}

+ (BOOL)socialFrameworkAvailable {
    
    if ([SHKCONFIG(forcePreIOS5TwitterAccess) boolValue])
    {
        return NO;
    }
    
	if (NSClassFromString(@"SLComposeViewController"))
    {
		return YES;
	}
	
	return NO;
}

- (void)prepareItem {

	NSString *status = [self.item customValueForKey:@"status"];
	if (!status)
	{
		status = self.item.shareType == SHKShareTypeText ? self.item.text : self.item.title;
	}
	
	//Only add the additional tags / URL if user has authorized his account
	if(self.isAuthorized) {
		NSString *hashtags = [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet]
		                                   tagPrefix:@"#" tagSuffix:nil];
		if ([hashtags length] > 0)
		{
			status = [NSString stringWithFormat:@"%@ %@", status, hashtags];
		}
    
		if (self.item.URL)
		{
			NSString *URLstring = [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			status = [NSString stringWithFormat:@"%@ %@", status, URLstring];
		}	
	}
	
    
	[self.item setCustomValue:status forKey:@"status"];
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
	if ([[self class] twitterFrameworkAvailable]) {
		[SHKTwitter logout];
		return NO; 
	}
	BOOL result = [self restoreAccessToken];
    if (result) {
        [self downloadAPIConfiguration]; //fetch file size limits
    }
    return result;
}

- (void)promptAuthorization
{	
	if ([[self class] twitterFrameworkAvailable]) {
		SHKLog(@"There is no need to authorize when we use iOS Twitter framework");
		return;
	}
	
	if (self.xAuth)
		[super authorizationFormShow]; // xAuth process
	
	else
		[super promptAuthorization]; // OAuth process		
}

+ (void)logout {
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKTwitterUserInfo];
	[super logout];    
}

#pragma mark xAuth

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"Twitter.com");
}

+ (NSArray *)authorizationFormFields
{
	if ([SHKCONFIG(twitterUsername) isEqualToString:@""])
		return [super authorizationFormFields];
	
	return [NSArray arrayWithObjects:
			  [SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeTextNoCorrect start:nil],
			  [SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],
			  [SHKFormFieldSettings label:SHKLocalizedString(@"Follow %@", SHKCONFIG(twitterUsername)) key:@"followMe" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOn],			
			  nil];
}

- (FormControllerCallback)authorizationFormValidate
{
	__weak typeof(self) weakSelf = self;
    
    FormControllerCallback result = ^(SHKFormController *form) {
        
        weakSelf.pendingForm = form;
        [weakSelf tokenAccess];
    };
    return result;
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{	
	if (self.xAuth)
	{
		NSDictionary *formValues = [self.pendingForm formValues];
		
		OARequestParameter *username = [[OARequestParameter alloc] initWithName:@"x_auth_username"
																								 value:[formValues objectForKey:@"username"]];
		
		OARequestParameter *password = [[OARequestParameter alloc] initWithName:@"x_auth_password"
																								 value:[formValues objectForKey:@"password"]];
		
		OARequestParameter *mode = [[OARequestParameter alloc] initWithName:@"x_auth_mode"
																							value:@"client_auth"];
		
		[oRequest setParameters:[NSArray arrayWithObjects:username, password, mode, nil]];
	} else {
        if (self.pendingAction == SHKPendingRefreshToken)
        {
            if (accessToken.sessionHandle != nil)
                [oRequest setOAuthParameterName:@"oauth_session_handle" withValue:accessToken.sessionHandle];
        } else if([authorizeResponseQueryVars objectForKey:@"oauth_verifier"]) {
            [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
        }
    }
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (self.xAuth)
	{
		if (ticket.didSucceed)
		{
			[self.item setCustomValue:[[self.pendingForm formValues] objectForKey:@"followMe"] forKey:@"followMe"];
			[self.pendingForm close];
		}
		
		else
		{
			NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			SHKLog(@"tokenAccessTicket Response Body: %@", response);
			
			[self tokenAccessTicket:ticket didFailWithError:[SHK error:response]];
			return;
		}
	}
	
	[super tokenAccessTicket:ticket didFinishWithData:data];		
}

#pragma mark -
#pragma mark UI Implementation

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {

    
    if (self.item.shareType == SHKShareTypeUserInfo) {
        self.quiet = YES;
        return nil;
    }
    
    [self prepareItem];
    
    SHKFormFieldLargeTextSettings *largeTextSettings = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Tweet")
                                                                                        key:@"status"
                                                                                       type:SHKFormFieldTypeTextLarge
                                                                                      start:[self.item customValueForKey:@"status"]
                                                                                       item:self.item];
    largeTextSettings.maxTextLength = [self maxTextLength];
    largeTextSettings.select = YES;
    largeTextSettings.validationBlock = ^(SHKFormFieldLargeTextSettings *formFieldSettings) {
        
        BOOL emptyCriterium =  [formFieldSettings.valueToSave length] > 0;
        BOOL maxTextLenCriterium = [formFieldSettings.valueToSave length] <= formFieldSettings.maxTextLength;
        
        if (emptyCriterium && maxTextLenCriterium) {
            return YES;
        } else {
            return NO;
        }
    };

    return @[largeTextSettings];
}

- (NSUInteger)maxTextLength {
    
    //if media is attached there is less room for user's tweet text
    NSUInteger textLengthToSubtract = 0;
    if (self.item.file) {
        textLengthToSubtract += [self charsReservedPerMedia];
    } else if (self.item.image) {
        textLengthToSubtract += [self charsReservedPerURL]; //the image link is shortened natively by Twitter anyway via t.co)
    }
    
    //if url is attached there is less room for user's tweet text
    if (self.item.URL) {
        textLengthToSubtract += [self charsReservedPerURL];
    }
    
    //link is shortened natively by Twitter via t.co, and the original link itself does not eat up to 140 chars limit, thus we add url length
    NSUInteger result = MAX_TWEET_LENGTH + [[self.item.URL absoluteString] length] - textLengthToSubtract;
    return result;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	// Check if we should send follow request too
	if (self.xAuth && [self.item customBoolForSwitchKey:@"followMe"])
		[self followMe];	
	
	if (![self validateItem]) return NO;
    
    if (self.item.image) {
        
        NSData *imageData = nil;
        if ([SHKTwitter canTwitterAcceptImage:self.item.image convertedData:&imageData]) {
            [self sendDataViaTwitter:imageData mimeType:@"image/jpeg" filename:@"upload.jpg"];
        } else {
            [self sendDataViaYFrog:imageData mimeType:@"image/jpeg" filename:@"upload.jpg"];
        }

    } else if (self.item.file) {
        
        if ([SHKTwitter canTwitterAcceptFile:self.item.file]) {
            [self sendDataViaTwitter:self.item.file.data mimeType:self.item.file.mimeType filename:self.item.file.filename];
        } else {
            [self sendDataViaYFrog:self.item.file.data mimeType:self.item.file.mimeType filename:self.item.file.filename];
        }
        
    } else if (self.item.shareType == SHKShareTypeUserInfo) {
        [self sendUserInfo];
    } else {
        [self sendStatus];
    }
	
	// Notify delegate
	[self sendDidStart];	
	
	return YES;
}

+ (BOOL)canTwitterAcceptFile:(SHKFile *)file {
    
    BOOL isSupportedImage = [file.mimeType isEqualToString:@"image/png"] || [file.mimeType isEqualToString:@"image/gif"] || [file.mimeType isEqualToString:@"image/jpeg"];
    BOOL isSizeSupported = file.size < [self maxTwitterFileSize];
    BOOL result = isSupportedImage && isSizeSupported;
    return result;
}

+ (BOOL)canTwitterAcceptImage:(UIImage *)image convertedData:(NSData **)data {
    
    CGFloat compression = 1;
	NSData *imageData = UIImageJPEGRepresentation(image, compression);
    *data = imageData;
    
    BOOL result = [imageData length] < [self maxTwitterFileSize];
    return result;
}

- (void)sendUserInfo {
	
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"]
																						 consumer:consumer
																							 token:accessToken
																							 realm:nil
																			 signatureProvider:nil];	
	[oRequest setHTTPMethod:@"GET"];
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																													  delegate:self
																										  didFinishSelector:@selector(sendTicket:didFinishWithData:)
																											 didFailSelector:@selector(sendTicket:didFailWithError:)];
	[fetcher start];
}

- (void)sendDataViaTwitter:(NSData *)data mimeType:(NSString *)mimeType filename:(NSString *)filename {
    
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update_with_media.json"]
                                                                    consumer:consumer
                                                                       token:accessToken
                                                                       realm:nil
                                                           signatureProvider:nil];
	[oRequest setHTTPMethod:@"POST"];
    [oRequest prepare];
    
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status" value:[self.item customValueForKey:@"status"]];
	[oRequest setParameters:@[statusParam]];
    [oRequest attachFileWithParameterName:@"media" filename:filename contentType:mimeType data:data];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
	[fetcher start];
}

- (void)sendDataViaYFrog:(NSData *)data mimeType:(NSString *)mimeType filename:(NSString *)filename {
    
    OAMutableURLRequest *uploadRequest = [[OAMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://yfrog.com/api/xauth_upload"]
                                                                         consumer:consumer
                                                                            token:accessToken
                                                                            realm:@"https://api.twitter.com/"
                                                                signatureProvider:signatureProvider];
    [uploadRequest setHTTPMethod:@"POST"];
    [uploadRequest setValue:@"https://api.twitter.com/1.1/account/verify_credentials.json" forHTTPHeaderField:@"X-Auth-Service-Provider"];
    [uploadRequest setValue:[self createOAuthHeaderForYFrog] forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    [uploadRequest attachFileWithParameterName:@"media" filename:filename contentType:mimeType data:data];
    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:uploadRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendYFrogTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
    [fetcher start];
}

- (NSString *)createOAuthHeaderForYFrog {
    
    OAMutableURLRequest *auth = [[OAMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/account/verify_credentials.xml"]
                                                                consumer:consumer token:accessToken
                                                                   realm:@"https://api.twitter.com/"
                                                       signatureProvider:signatureProvider];
    [auth prepare];
    NSDictionary *headerDict = [auth allHTTPHeaderFields];
    NSString *result = [[NSString alloc] initWithString:[headerDict valueForKey:@"Authorization"]];
    return result;
}

- (void)sendYFrogTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    
    if (ticket.didSucceed) {
        
        NSString *mediaURL = [SHKXMLResponseParser getValueForElement:@"mediaurl" fromResponse:data];
        if (mediaURL) {
            
            [self.item setCustomValue:[NSString stringWithFormat:@"%@ %@", [self.item customValueForKey:@"status"], mediaURL] forKey:@"status"];
			[self sendStatus];
            
        } else {
            
            [self handleUnsuccessfulTicket:data];
        }
    } else {
        [self sendShowSimpleErrorAlert];
    }
}

- (void)sendStatus
{
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"]
																						 consumer:consumer
																							 token:accessToken
																							 realm:nil
																			 signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status"
																								value:[self.item customValueForKey:@"status"]];
    NSArray *params = [NSArray arrayWithObjects:statusParam, nil];
	[oRequest setParameters:params];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																													  delegate:self
                                                                                 didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
	
	[fetcher start];
}

- (void)followMe
{
	// remove it so in case of other failures this doesn't get hit again
	[self.item setCustomValue:nil forKey:@"followMe"];
	
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/friendships/create/%@.json", SHKCONFIG(twitterUsername)]]
																						 consumer:consumer
																							 token:accessToken
																							 realm:nil
																			 signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																													  delegate:nil // Currently not doing any error handling here.  If it fails, it's probably best not to bug the user to follow you again.
																										  didFinishSelector:nil
																											 didFailSelector:nil];	
	
	[fetcher start];
}

#pragma mark -

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {

	if (ticket.didSucceed) {
        
        if (self.item.shareType == SHKShareTypeUserInfo) [self saveData:data defaultsKey:kSHKTwitterUserInfo];
		[self sendDidFinish];

    } else {
        
		[self handleUnsuccessfulTicket:data];
	}
}

- (void)handleUnsuccessfulTicket:(NSData *)data
{
	if (SHKDebugShowLogs)
		SHKLog(@"Twitter Send Status Error: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	NSMutableDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSDictionary *twitterError = parsedResponse[@"errors"][0];
	
	if ([twitterError[@"code"] integerValue] == REVOKED_ACCESS_ERROR_CODE) {
		
		[self shouldReloginWithPendingAction:SHKPendingSend];
        return;
		
	} else {
		
		//when sharing image, and the user removed app permissions there is no JSON response expected above, but XML, which we need to parse. 401 is obsolete credentials -> need to relogin
		if ([[SHKXMLResponseParser getValueForElement:@"code" fromResponse:data] isEqualToString:@"401"]) {
			
			[self shouldReloginWithPendingAction:SHKPendingSend];
			return;
		}
	}
	
	NSError *error = [NSError errorWithDomain:@"Twitter" code:2 userInfo:[NSDictionary dictionaryWithObject:twitterError[@"message"] forKey:NSLocalizedDescriptionKey]];
	[self sendDidFailWithError:error];
}

@end
