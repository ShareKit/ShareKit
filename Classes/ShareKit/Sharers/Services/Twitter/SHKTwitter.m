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

static NSString *const kSHKTwitterUserInfo=@"kSHKTwitterUserInfo";

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

- (BOOL)requiresShortenedURL
{
    return YES;
}

#pragma mark -
#pragma mark Commit Share

- (void)share {
	if ([self socialFrameworkAvailable])
	{
		SHKSharer *sharer = [SHKiOSTwitter shareItem:self.item];
		[self setupiOSSharer:sharer];
	}
	else if ([self twitterFrameworkAvailable])
	{
		SHKSharer *sharer = [SHKiOS5Twitter shareItem:self.item];
		[self setupiOSSharer:sharer];
	}
	else
	{
        [self prepareItem];
        [super share];
	}
}

- (void)setupiOSSharer:(SHKSharer *)sharer {
    sharer.quiet = self.quiet;
    sharer.shareDelegate = self.shareDelegate;
    [SHKTwitter logout];//to clean credentials - we will not need them anymore
}

#pragma mark -

- (BOOL)twitterFrameworkAvailable {
	
    if ([SHKCONFIG(forcePreIOS5TwitterAccess) boolValue])
    {
        return NO;
    }
    
	if (NSClassFromString(@"TWTweetComposeViewController")) {
		return YES;
	}
	
	return NO;
}

- (BOOL)socialFrameworkAvailable {
    
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
	if ([self twitterFrameworkAvailable]) {
		[SHKTwitter logout];
		return NO; 
	}
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{	
	if ([self twitterFrameworkAvailable]) {
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
    
    if (type == SHKShareTypeUserInfo) {
        self.quiet = YES;
        return nil;
    }
    
    NSArray *result = @[[SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Tweet")
                                                         key:@"status"
                                                        type:SHKFormFieldTypeTextLarge
                                                       start:[self.item customValueForKey:@"status"]
                                               maxTextLength:140
                                                       image:self.item.image
                                             imageTextLength:25
                                                        link:self.item.URL
                                                        file:nil
                                              allowEmptySend:NO
                                                      select:YES]];
    return result;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)validateItem {
	
	if (self.item.shareType == SHKShareTypeUserInfo) return YES;
    
	BOOL isValid = [super validateItem];
	NSString *status = [self.item customValueForKey:@"status"];
	
	if (isValid && 0 < status.length && status.length <= 140) {
		return YES;
	} else {
        return NO;
    }
}

- (BOOL)send
{	
	// Check if we should send follow request too
	if (self.xAuth && [self.item customBoolForSwitchKey:@"followMe"])
		[self followMe];	
	
	if (![self validateItem])
		return NO;
	
	switch (self.item.shareType) {
			
		case SHKShareTypeImage:            
			[self sendImage];
			break;
			
		case SHKShareTypeUserInfo:            
			[self sendUserInfo];
			break;
			
		default:
			[self sendStatus];
			break;
	}
	
	// Notify delegate
	[self sendDidStart];	
	
	return YES;
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
																										  didFinishSelector:@selector(sendUserInfo:didFinishWithData:)
																											 didFailSelector:@selector(sendUserInfo:didFailWithError:)];		
	[fetcher start];
}

- (void)sendUserInfo:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
	if (ticket.didSucceed) {
		
		NSError *error = nil;
		NSMutableDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
		
		if (error) {
			SHKLog(@"Error when parsing json twitter user info request:%@", [error description]);
		}
		
		[userInfo convertNSNullsToEmptyStrings];
		[[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKTwitterUserInfo];
		
		[self sendDidFinish];
		
	} else {
		
		[self handleUnsuccessfulTicket:data];
	}
}

- (void)sendUserInfo:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
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
																										  didFinishSelector:@selector(sendStatusTicket:didFinishWithData:)
																											 didFailSelector:@selector(sendStatusTicket:didFailWithError:)];	
	
	[fetcher start];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
	// TODO better error handling here
	
	if (ticket.didSucceed) 
		[self sendDidFinish];
	
	else
	{		
		[self handleUnsuccessfulTicket:data];
	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

- (void)sendImage {
	
	NSURL *serviceURL = nil;
	if([self.item customValueForKey:@"profile_update"]){//update_profile does not work
		serviceURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/update_profile_image.json"];
	} else {
		serviceURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/account/verify_credentials.json"];
	}
	
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:serviceURL
																						 consumer:consumer
																							 token:accessToken
																							 realm:@"https://api.twitter.com/"
																			 signatureProvider:signatureProvider];
	[oRequest setHTTPMethod:@"GET"];
	
	if([self.item customValueForKey:@"profile_update"]){//update_profile does not work
		[oRequest prepare];
	} else {
		[oRequest prepare];
		
		NSDictionary * headerDict = [oRequest allHTTPHeaderFields];
		NSString * oauthHeader = [NSString stringWithString:[headerDict valueForKey:@"Authorization"]];
		
		oRequest = nil;
		
		serviceURL = [NSURL URLWithString:@"http://img.ly/api/2/upload.xml"];
		oRequest = [[OAMutableURLRequest alloc] initWithURL:serviceURL
																 consumer:consumer
																	 token:accessToken
																	 realm:@"https://api.twitter.com/"
													 signatureProvider:signatureProvider];
		[oRequest setHTTPMethod:@"POST"];
		[oRequest setValue:@"https://api.twitter.com/1.1/account/verify_credentials.json" forHTTPHeaderField:@"X-Auth-Service-Provider"];
		[oRequest setValue:oauthHeader forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
	}
	
	CGFloat compression = 0.9f;
	NSData *imageData = UIImageJPEGRepresentation([self.item image], compression);
	
	// TODO
	// Note from Nate to creator of sendImage method - This seems like it could be a source of sluggishness.
	// For example, if the image is large (say 3000px x 3000px for example), it would be better to resize the image
	// to an appropriate size (max of img.ly) and then start trying to compress.
	
	while ([imageData length] > 700000 && compression > 0.1) {
		// SHKLog(@"Image size too big, compression more: current data size: %d bytes",[imageData length]);
		compression -= 0.1;
		imageData = UIImageJPEGRepresentation([self.item image], compression);
		
	}
	
	NSString *boundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[oRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *body = [NSMutableData data];
	NSString *dispKey = @"";
	if([self.item customValueForKey:@"profile_update"]){//update_profile does not work
		dispKey = @"Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\"\r\n";
	} else {
		dispKey = @"Content-Disposition: form-data; name=\"media\"; filename=\"upload.jpg\"\r\n";
	}
	
	
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[dispKey dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageData];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	if([self.item customValueForKey:@"profile_update"]){//update_profile does not work
		// no ops
	} else {
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"message\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[self.item customValueForKey:@"status"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];	
	}
	
	[body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// setting the body of the post to the reqeust
	[oRequest setHTTPBody:body];
	
	// Notify delegate
	[self sendDidStart];
	
	// Start the request
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																													  delegate:self
																										  didFinishSelector:@selector(sendImageTicket:didFinishWithData:)
																											 didFailSelector:@selector(sendImageTicket:didFailWithError:)];	
	
	[fetcher start];
	
	
}

- (void)sendImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	// TODO better error handling here
	// SHKLog([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	if (ticket.didSucceed) {
		// Finished uploading Image, now need to posh the message and url in twitter
		NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSRange startingRange = [dataString rangeOfString:@"<url>" options:NSCaseInsensitiveSearch];
		//SHKLog(@"found start string at %d, len %d",startingRange.location,startingRange.length);
		NSRange endingRange = [dataString rangeOfString:@"</url>" options:NSCaseInsensitiveSearch];
		//SHKLog(@"found end string at %d, len %d",endingRange.location,endingRange.length);
		
		if (startingRange.location != NSNotFound && endingRange.location != NSNotFound) {
			NSString *urlString = [dataString substringWithRange:NSMakeRange(startingRange.location + startingRange.length, endingRange.location - (startingRange.location + startingRange.length))];
			//SHKLog(@"extracted string: %@",urlString);
			[self.item setCustomValue:[NSString stringWithFormat:@"%@ %@",[self.item customValueForKey:@"status"],urlString] forKey:@"status"];
			[self sendStatus];
		} else {
			[self handleUnsuccessfulTicket:data];
		}
		
		
	} else {
		[self sendDidFailWithError:nil];
	}
}

- (void)sendImageTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error {
	[self sendDidFailWithError:error];
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

- (void)handleUnsuccessfulTicket:(NSData *)data
{
	if (SHKDebugShowLogs)
		SHKLog(@"Twitter Send Status Error: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	// CREDIT: Oliver Drobnik
	
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];		
	
	// in case our makeshift parsing does not yield an error message
	NSString *errorMessage = @"Unknown Error";		
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	// skip until error message
	[scanner scanUpToString:@"\"error\":\"" intoString:nil];
	
	
	if ([scanner scanString:@"\"error\":\"" intoString:nil])
	{
		// get the message until the closing double quotes
		[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&errorMessage];
	}
	
	
	// this is the error message for revoked access ...?... || removed app from Twitter
	if ([errorMessage isEqualToString:@"Invalid / used nonce"] || [errorMessage isEqualToString:@"Could not authenticate with OAuth."]) {
		
		[self shouldReloginWithPendingAction:SHKPendingSend];
		
	} else {
		
		//when sharing image, and the user removed app permissions there is no JSON response expected above, but XML, which we need to parse. 401 is obsolete credentials -> need to relogin
		if ([[SHKXMLResponseParser getValueForElement:@"code" fromResponse:data] isEqualToString:@"401"]) {
			
			[self shouldReloginWithPendingAction:SHKPendingSend];
			return;
		}
	}
	
	NSError *error = [NSError errorWithDomain:@"Twitter" code:2 userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
	[self sendDidFailWithError:error];
}

@end
