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
#import "SHKTwitterCommon.h"

#import <Social/Social.h>

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
    
    BOOL result = [SHKTwitterCommon canShareFile:file];
    return result;
}

+ (BOOL)canShare {
    
    BOOL result = ![SHKTwitterCommon socialFrameworkAvailable];
    return result;
}

- (void)downloadAPIConfiguration {
    
    NSDate *lastFetchDate = [[NSUserDefaults standardUserDefaults] objectForKey:SHKTwitterAPIConfigurationSaveDateKey];
    BOOL isConfigOld = [[NSDate date] compare:[lastFetchDate dateByAddingTimeInterval:24*60*60]] == NSOrderedDescending;
    if (isConfigOld || !lastFetchDate) {
        
            OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:SHKTwitterAPIConfigurationURL]
                                                                            consumer:self.consumer
                                                                               token:self.accessToken
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
        
        [SHKTwitterCommon saveData:data defaultsKey:SHKTwitterAPIConfigurationDataKey];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SHKTwitterAPIConfigurationSaveDateKey];
        
    } else {
        
        SHKLog(@"Error when fetching Twitter config:%@", ticket.body);
    }
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{
    BOOL result = [self restoreAccessToken];
    if (result) {
        [self downloadAPIConfiguration]; //fetch fresh file size limits
    }
    return result;
}

- (void)promptAuthorization
{	
	if (self.xAuth)
		[super authorizationFormShow]; // xAuth process
	
	else
		[super promptAuthorization]; // OAuth process		
}

+ (void)logout {
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKTwitterUserInfo];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKTwitterAPIConfigurationDataKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKTwitterAPIConfigurationSaveDateKey];
	[super logout];    
}

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKTwitterUserInfo];
    NSString *result = userInfo[SHKTwitterAPIUserInfoNameKey];
    return result;
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
            if (self.accessToken.sessionHandle != nil)
                [oRequest setOAuthParameterName:@"oauth_session_handle" withValue:self.accessToken.sessionHandle];
        } else if([self.authorizeResponseQueryVars objectForKey:@"oauth_verifier"]) {
            [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[self.authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
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

    
    if (self.item.shareType == SHKShareTypeUserInfo) return nil;
    
    [SHKTwitterCommon prepareItem:self.item joinedTags:[self tagStringJoinedBy:@" "
                                                             allowedCharacters:[NSCharacterSet alphanumericCharacterSet]
                                                                     tagPrefix:@"#" tagSuffix:nil]];
    
    SHKFormFieldLargeTextSettings *largeTextSettings = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Tweet")
                                                                                        key:@"status"
                                                                                      start:[self.item customValueForKey:@"status"]
                                                                                       item:self.item];
    largeTextSettings.maxTextLength = [SHKTwitterCommon maxTextLengthForItem:self.item];
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

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
    //Needed for silent share. Normally status is aggregated just before presenting the UI
    if (![self.item customValueForKey:@"status"]) {
        
        [SHKTwitterCommon prepareItem:self.item joinedTags:[self tagStringJoinedBy:@" "
                                                                 allowedCharacters:[NSCharacterSet alphanumericCharacterSet]
                                                                         tagPrefix:@"#" tagSuffix:nil]];
    }
    
	// Check if we should send follow request too
	if (self.xAuth && [self.item customBoolForSwitchKey:@"followMe"])
		[self followMe];	
	
	if (![self validateItem]) return NO;
    
    if (self.item.image || self.item.file) {
        
        if (self.item.image && !self.item.file) {
            [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:1];
        }
        
        if ([SHKTwitterCommon canTwitterAcceptFile:self.item.file]) {
            [self sendFileViaTwitter:self.item.file];
        } else {
            [self sendFileViaYFrog:self.item.file];
        }
        
    } else if (self.item.shareType == SHKShareTypeUserInfo) {
        self.quiet = YES;
        [self sendUserInfo];
    } else {
        [self sendStatus];
    }
	
	// Notify delegate
	[self sendDidStart];	
	
	return YES;
}

- (void)sendUserInfo {
	
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:SHKTwitterAPIUserInfoURL]
                                                                    consumer:self.consumer
                                                                       token:self.accessToken
                                                                       realm:nil
                                                           signatureProvider:nil];	
	[oRequest setHTTPMethod:@"GET"];
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																													  delegate:self
																										  didFinishSelector:@selector(sendTicket:didFinishWithData:)
																											 didFailSelector:@selector(sendTicket:didFailWithError:)];
	[fetcher start];
}

- (void)sendFileViaTwitter:(SHKFile *)file {
    
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:SHKTwitterAPIUpdateWithMediaURL]
                                                                    consumer:self.consumer
                                                                       token:self.accessToken
                                                                       realm:nil
                                                           signatureProvider:nil];
	[oRequest setHTTPMethod:@"POST"];
    [oRequest prepare];
    
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status" value:[self.item customValueForKey:@"status"]];
	[oRequest setParameters:@[statusParam]];
    [oRequest attachFile:file withParameterName:@"media"];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
	[fetcher start];
}

- (void)sendFileViaYFrog:(SHKFile *)file {
    
    OAMutableURLRequest *uploadRequest = [[OAMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://yfrog.com/api/xauth_upload"]
                                                                         consumer:self.consumer
                                                                            token:self.accessToken
                                                                            realm:@"https://api.twitter.com/"
                                                                signatureProvider:self.signatureProvider];
    [uploadRequest setHTTPMethod:@"POST"];
    [uploadRequest setValue:@"https://api.twitter.com/1.1/account/verify_credentials.json" forHTTPHeaderField:@"X-Auth-Service-Provider"];
    [uploadRequest setValue:[self createOAuthHeaderForYFrog] forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    [uploadRequest attachFile:file withParameterName:@"media"];
    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:uploadRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendYFrogTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
    [fetcher start];
}

- (NSString *)createOAuthHeaderForYFrog {
    
    OAMutableURLRequest *auth = [[OAMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/account/verify_credentials.xml"]
                                                                consumer:self.consumer
                                                                   token:self.accessToken
                                                                   realm:@"https://api.twitter.com/"
                                                       signatureProvider:self.signatureProvider];
    [auth prepare];
    NSDictionary *headerDict = [auth allHTTPHeaderFields];
    NSString *result = [[NSString alloc] initWithString:[headerDict valueForKey:@"Authorization"]];
    return result;
}

- (void)sendYFrogTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    
    if (ticket.didSucceed) {
        
        NSString *mediaURL = [SHKXMLResponseParser getValueForElement:@"mediaurl" fromXMLData:data];
        if (mediaURL) {
            
            [self.item setCustomValue:[NSString stringWithFormat:@"%@ %@", [self.item customValueForKey:@"status"], mediaURL] forKey:@"status"];
			[self sendStatus];
            
        } else {
            
            [SHKTwitterCommon handleUnsuccessfulTicket:data forSharer:self];
        }
    } else {
        [self sendShowSimpleErrorAlert];
    }
}

- (void)sendStatus
{
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:SHKTwitterAPIUpdateURL]
                                                                    consumer:self.consumer
                                                                       token:self.accessToken
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
                                                                    consumer:self.consumer
                                                                       token:self.accessToken
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
        
        if (self.item.shareType == SHKShareTypeUserInfo) [SHKTwitterCommon saveData:data defaultsKey:kSHKTwitterUserInfo];
		[self sendDidFinish];

    } else {
        
		[SHKTwitterCommon handleUnsuccessfulTicket:data forSharer:self];
	}
}

@end
