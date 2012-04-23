//
//  SHKReadability.m
//  ShareKit
//
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


#import "SHKConfiguration.h"
#import "SHKReadability.h"
#import "JSONKit.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

static NSString *const kSHKReadabilityUserInfo=@"kSHKReadabilityUserInfo";

@interface SHKReadability ()

- (void)handleUnsuccessfulTicket:(NSData *)data;

@end

@implementation SHKReadability

@synthesize xAuth;

- (id)init
{
	if (self = [super init])
	{	
		// OAUTH		
		self.consumerKey = SHKCONFIG(readabilityConsumerKey);		
		self.secretKey = SHKCONFIG(readabilitySecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:@""];
		
		// XAUTH
		self.xAuth = [SHKCONFIG(readabilityUseXAuth) boolValue]?YES:NO;
		
		
		// -- //
		
		
		// You do not need to edit these, they are the same for everyone
		self.authorizeURL = [NSURL URLWithString:@"https://www.readability.com/api/rest/v1/oauth/authorize/"];
		self.requestURL = [NSURL URLWithString:@"https://www.readability.com/api/rest/v1/oauth/request_token/"];
		self.accessURL = [NSURL URLWithString:@"https://www.readability.com/api/rest/v1/oauth/access_token/"]; 
	}	
	return self;
}


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Readability";
}

+ (BOOL)canShareURL
{
	return YES;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{	
	
	if (xAuth)
		[super authorizationFormShow]; // xAuth process
	
	else
		[super promptAuthorization]; // OAuth process		
}

+ (void)logout {
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKReadabilityUserInfo];
	[super logout];    
}

#pragma mark xAuth

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"Readability.com");
}

+ (NSArray *)authorizationFormFields
{
	
	return [NSArray arrayWithObjects:
			  [SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeTextNoCorrect start:nil],
			  [SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],
			  nil];
}

- (void)authorizationFormValidate:(SHKFormController *)form
{
	self.pendingForm = form;
	[self tokenAccess];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{	
	if (xAuth)
	{
		NSDictionary *formValues = [pendingForm formValues];
		
		OARequestParameter *username = [[[OARequestParameter alloc] initWithName:@"x_auth_username"
																								 value:[formValues objectForKey:@"username"]] autorelease];
		
		OARequestParameter *password = [[[OARequestParameter alloc] initWithName:@"x_auth_password"
																								 value:[formValues objectForKey:@"password"]] autorelease];
		
		OARequestParameter *mode = [[[OARequestParameter alloc] initWithName:@"x_auth_mode"
																							value:@"client_auth"] autorelease];
		
		[oRequest setParameters:[NSArray arrayWithObjects:username, password, mode, nil]];
	}
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (xAuth) 
	{
		if (ticket.didSucceed)
		{
			[pendingForm close];
		}
		
		else
		{
			NSString *response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			SHKLog(@"tokenAccessTicket Response Body: %@", response);
			
			[self tokenAccessTicket:ticket didFailWithError:[SHK error:response]];
			return;
		}
	}
	
	[super tokenAccessTicket:ticket didFinishWithData:data];		
}


#pragma mark -
#pragma mark UI Implementation

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	if (type == SHKShareTypeURL)
		return [NSArray arrayWithObjects:
            [SHKFormFieldSettings label:SHKLocalizedString(@"Favorite") key:@"favorite" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOff],
            [SHKFormFieldSettings label:SHKLocalizedString(@"Archive") key:@"archive" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOff],
            nil];
	
	return nil;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	switch (item.shareType) {
			
		case SHKShareTypeURL:            
			[self sendBookmark];
			break;
			
		default:
			[self sendBookmark];
			break;
	}
	
	// Notify delegate
	[self sendDidStart];	
	
	return YES;
}

- (void)sendBookmark
{
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.readability.com/api/rest/v1/bookmarks/"]
                                                                  consumer:consumer // this is a consumer object already made available to us
                                                                     token:accessToken // this is our accessToken already made available to us
                                                                     realm:nil
                                                         signatureProvider:signatureProvider];
	
	[oRequest setHTTPMethod:@"POST"];
	
  BOOL isFavorite = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_isFavorite", [self sharerId]]];
  BOOL shouldArchive = [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_shouldArchive", [self sharerId]]];
  
	OARequestParameter *bookmarkParam = [[OARequestParameter alloc] initWithName:@"url"
																								value:[item.URL absoluteString]];
  OARequestParameter *favoriteParam = [[OARequestParameter alloc] initWithName:@"favorite"
                                                                         value:isFavorite?@"1":@"0"];
  OARequestParameter *archiveParam = [[OARequestParameter alloc] initWithName:@"archive"
                                                                         value:shouldArchive?@"1":@"0"];
	NSArray *params = [NSArray arrayWithObjects:bookmarkParam, favoriteParam, archiveParam, nil];
	[oRequest setParameters:params];
	[bookmarkParam release];
  [favoriteParam release];
  [archiveParam release];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																													  delegate:self
																										  didFinishSelector:@selector(sendBookmarkTicket:didFinishWithData:)
																											 didFailSelector:@selector(sendBookmarkTicket:didFailWithError:)];	
	
	[fetcher start];
	[oRequest release];
}

- (void)sendBookmarkTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
	// TODO better error handling here
	
	if (ticket.didSucceed) 
		[self sendDidFinish];
	
	else
	{		
		[self handleUnsuccessfulTicket:data];
	}
}

- (void)sendBookmarkTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

#pragma mark -

- (void)handleUnsuccessfulTicket:(NSData *)data
{
	if (SHKDebugShowLogs)
		SHKLog(@"Readability Send Bookmark Error: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
		
	NSString *errorMessage = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];			
  
	// this is the error message for revoked access, Readability Error Message: "You are unauthenticated.  (API protected by OAuth)."
	if ([errorMessage rangeOfString:@"unauthenticated"].location != NSNotFound) {
		[self shouldReloginWithPendingAction:SHKPendingSend];
        return;
	}
	NSDictionary *errorDict = [errorMessage objectFromJSONString];

	if ([[errorDict objectForKey:@"success"] intValue] == 0)
	{
        NSError * error = nil;
        if ([[errorDict objectForKey:@"messages"] isKindOfClass:[NSArray class]]) {
            error = [NSError errorWithDomain:@"Readability" code:2 userInfo:[NSDictionary dictionaryWithObject:[[errorDict objectForKey:@"messages"] objectAtIndex:0] forKey:NSLocalizedDescriptionKey]];
        }
        if ([[errorDict objectForKey:@"messages"] objectForKey:@"url"]) {
            error = [NSError errorWithDomain:@"Readability" code:2 userInfo:[NSDictionary dictionaryWithObject:[[[errorDict objectForKey:@"messages"] objectForKey:@"url"] objectAtIndex:0] forKey:NSLocalizedDescriptionKey]];
        }
        [self sendDidFailWithError:error];
	} else {
        [self sendDidFinish]; //otherways HUD might spin forever if success is 1
    }
}

- (void)shareFormSave:(SHKFormController *)form
{
	[super shareFormSave:form];
  
	// If the user turned autoshare on, record whether they want the links public or not when they're shared.
	NSDictionary *formValues = [form formValues];
	for(NSString *key in formValues)
	{
		if ([key isEqualToString:@"favorite"])
		{
			[[NSUserDefaults standardUserDefaults] setBool:[formValues objectForKey:key] == SHKFormFieldSwitchOn forKey:[NSString stringWithFormat:@"%@_isFavorite", [self sharerId]]];
		}
    if ([key isEqualToString:@"archive"])
		{
			[[NSUserDefaults standardUserDefaults] setBool:[formValues objectForKey:key] == SHKFormFieldSwitchOn forKey:[NSString stringWithFormat:@"%@_shouldArchive", [self sharerId]]];
		}
	}
}

@end
