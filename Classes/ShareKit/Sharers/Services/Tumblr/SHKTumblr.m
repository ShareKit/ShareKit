//
//  SHKTumblr.m
//  ShareKit
//
//  Created by Che-Bin Liu on 10/17/12.
//

#import "SHKTumblr.h"
#import "SHKConfiguration.h"
#import "JSONKit.h"
#import "SHKXMLResponseParser.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"
#import "NSMutableURLRequest+Parameters.h"

static NSString *const kSHKTumblrUserInfo = @"kSHKTumblrUserInfo";
static NSString *const kSHKTumblrLastBlog = @"kSHKTumblrLastBlog";

@implementation SHKTumblr

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle{
	return @"Tumblr";
}

+ (BOOL)canShareURL{
	return YES;
}

+ (BOOL)canShareText{
	return YES;
}

+ (BOOL)canShareImage{
	return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare{
	return YES;
}

+ (BOOL)canAutoShare{
	return NO;
}

#pragma mark -
#pragma mark Commit Share

- (void)share
{
	if (item.shareType == SHKShareTypeImage) {
		[item setCustomValue:item.title forKey:@"caption"];
	}
	[super share];
}

#pragma mark -
#pragma mark Authorization

- (id)init
{
	if (self = [super init])
	{
		// OAUTH
		self.consumerKey = SHKCONFIG(tumblrConsumerKey);
		self.secretKey = SHKCONFIG(tumblrSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(tumblrCallbackUrl)];
		
		// XAUTH
		xAuth = [SHKCONFIG(tumblrUseXAuth) boolValue]?YES:NO;
		
		
		// -- //
		
		
		// You do not need to edit these, they are the same for everyone
		self.authorizeURL = [NSURL URLWithString:@"http://www.tumblr.com/oauth/authorize"];
		self.requestURL = [NSURL URLWithString:@"http://www.tumblr.com/oauth/request_token"];
		if (xAuth) {
			self.accessURL = [NSURL URLWithString:@"https://www.tumblr.com/oauth/access_token"];
		}
		else {
			self.accessURL = [NSURL URLWithString:@"http://www.tumblr.com/oauth/access_token"];
		}
		
		self.signatureProvider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
	}
	return self;
}

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

+ (void)logout
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKTumblrUserInfo];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKTumblrLastBlog];
	[super logout];
}

#pragma mark xAuth

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"Tumblr.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form
{
	self.pendingForm = form;
	[self tokenAccess];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	if (xAuth) {
		NSDictionary *formValues = [pendingForm formValues];
		
		OARequestParameter *username = [[[OARequestParameter alloc] initWithName:@"x_auth_username"
																		   value:[formValues objectForKey:@"username"]] autorelease];
		OARequestParameter *password = [[[OARequestParameter alloc] initWithName:@"x_auth_password"
																		   value:[formValues objectForKey:@"password"]] autorelease];
		OARequestParameter *mode = [[[OARequestParameter alloc] initWithName:@"x_auth_mode"
																	   value:@"client_auth"] autorelease];
		[oRequest setParameters:[NSArray arrayWithObjects:username, password, mode, nil]];
	}
	else {
		SHKLog(@"req: %@", authorizeResponseQueryVars);
		[oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
	}
}

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
	if (!xAuth) {
		[oRequest setOAuthParameterName:@"oauth_callback" withValue:[self.authorizeCallbackURL absoluteString]];
		
		// We need the rw_nus scope to be able to share messages.
		//[oRequest setOAuthParameterName:@"scope" withValue:SHKLinkedInRequiredScope];
	}
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (xAuth) {
		if (ticket.didSucceed) {
			[pendingForm close];
		}
		else {
			NSString *response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			SHKLog(@"tokenAccessTicket Response Body: %@", response);
			
			[self tokenAccessTicket:ticket didFailWithError:[SHK error:response]];
			return;
		}
	}
	
	[super tokenAccessTicket:ticket didFinishWithData:data];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	NSMutableArray *baseArray = [NSMutableArray arrayWithObjects:
								 [SHKFormFieldSettings label:SHKLocalizedString(@"Blog")
														 key:@"blog"
														type:SHKFormFieldTypeOptionPicker
													   start:[[NSUserDefaults standardUserDefaults] objectForKey:kSHKTumblrLastBlog]
											optionPickerInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:SHKLocalizedString(@"Tumblr Blogs"), @"title",
															  @"-1", @"curIndexes",
															  [NSArray array],@"itemsList",
															  [NSNumber numberWithBool:NO], @"static",
															  [NSNumber numberWithBool:NO], @"allowMultiple",
															  self, @"SHKFormOptionControllerOptionProvider",
															  nil]
									optionDetailLabelDefault:SHKLocalizedString(@"Select Blog")],
								 [SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag")
														 key:@"tags"
														type:SHKFormFieldTypeText
													   start:[item.tags componentsJoinedByString:@", "]],
								 [SHKFormFieldSettings label:SHKLocalizedString(@"Slug")
														 key:@"slug"
														type:SHKFormFieldTypeText
													   start:nil],
								 [SHKFormFieldSettings label:SHKLocalizedString(@"Private")
														 key:@"private"
														type:SHKFormFieldTypeSwitch
													   start:SHKFormFieldSwitchOff],
								 [SHKFormFieldSettings label:SHKLocalizedString(@"Send to Twitter")
														 key:@"twitter"
														type:SHKFormFieldTypeSwitch
													   start:SHKFormFieldSwitchOff],
								 nil
								 ];
	if ([item shareType] == SHKShareTypeImage) {
		[baseArray insertObject:[SHKFormFieldSettings label:SHKLocalizedString(@"Caption")
														key:@"caption"
													   type:SHKFormFieldTypeText
													  start:item.title]
						atIndex:1];
	} else {
		[baseArray insertObject:[SHKFormFieldSettings label:SHKLocalizedString(@"Title")
														key:@"title"
													   type:SHKFormFieldTypeText
													  start:item.title]
						atIndex:1];
	}
	return baseArray;
}

#pragma mark -
#pragma mark Share API Methods

- (void)shareFormValidate:(SHKFormController *)form
{
	if ([[form formValues] objectForKey:@"blog"] == nil || [[[form formValues] objectForKey:@"blog"] isEqualToString:@""]) {
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Error")
									 message:SHKLocalizedString(@"Please select a blog.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:[[form formValues] objectForKey:@"blog"] forKey:kSHKTumblrLastBlog];
	}
	[form saveForm];
}

- (BOOL)send
{
	if (![self validateItem])
		return NO;
	
	if (item.shareType != SHKShareTypeURL && item.shareType != SHKShareTypeImage && item.shareType != SHKShareTypeText) {
		return NO;
	}
	
	NSString *tumblrURL = [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post", [item customValueForKey:@"blog"]];
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:tumblrURL]
																	consumer:consumer
																	   token:accessToken
																	   realm:nil
														   signatureProvider:signatureProvider];
	[oRequest setHTTPMethod:@"POST"];
	
	NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@","] invertedSet];
	NSString *tags = [self tagStringJoinedBy:@"," allowedCharacters:allowedCharacters tagPrefix:nil];
	NSString *slug = [item customValueForKey:@"slug"] ? [item customValueForKey:@"slug"] : @"";
	NSString *private = [item customBoolForSwitchKey:@"private"] ? @"private" : @"published";
	NSString *shouldTweet = [item customBoolForSwitchKey:@"twitter"] ? @"" : @"off";
	
	if (item.shareType == SHKShareTypeURL) {
		OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"link"];
		OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title" value:item.title];
		OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"url" value:[item.URL absoluteString]];
		OARequestParameter *tweetParam = [[OARequestParameter alloc] initWithName:@"tweet" value:shouldTweet];
		OARequestParameter *tagsParam = [[OARequestParameter alloc] initWithName:@"tags" value:tags];
		OARequestParameter *slugParam = [[OARequestParameter alloc] initWithName:@"slug" value:slug];
		OARequestParameter *privateParam = [[OARequestParameter alloc] initWithName:@"state" value:private];
		NSArray *params = [NSArray arrayWithObjects:typeParam, titleParam, urlParam, tweetParam, tagsParam, slugParam, privateParam, nil];
		[oRequest setParameters:params];
		[typeParam release];
		[titleParam release];
		[urlParam release];
		[tweetParam release];
		[tagsParam release];
		[slugParam release];
		[privateParam release];
	}
	else if (item.shareType == SHKShareTypeText) {
		OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"text"];
		OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title" value:item.title];
		OARequestParameter *bodyParam = [[OARequestParameter alloc] initWithName:@"body" value:item.text];
		OARequestParameter *tweetParam = [[OARequestParameter alloc] initWithName:@"tweet" value:shouldTweet];
		OARequestParameter *tagsParam = [[OARequestParameter alloc] initWithName:@"tags" value:tags];
		OARequestParameter *slugParam = [[OARequestParameter alloc] initWithName:@"slug" value:slug];
		OARequestParameter *privateParam = [[OARequestParameter alloc] initWithName:@"state" value:private];
		NSArray *params = [NSArray arrayWithObjects:typeParam, titleParam, bodyParam, tweetParam, tagsParam, slugParam, privateParam, nil];
		[oRequest setParameters:params];
		[typeParam release];
		[titleParam release];
		[bodyParam release];
		[tweetParam release];
		[tagsParam release];
		[slugParam release];
		[privateParam release];
	}
	else if (item.shareType == SHKShareTypeImage) {
		OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"photo"];
		OARequestParameter *captionParam = [[OARequestParameter alloc] initWithName:@"caption" value:[item customValueForKey:@"caption"]?[item customValueForKey:@"caption"]:@""];
		OARequestParameter *tweetParam = [[OARequestParameter alloc] initWithName:@"tweet" value:shouldTweet];
		OARequestParameter *tagsParam = [[OARequestParameter alloc] initWithName:@"tags" value:tags];
		OARequestParameter *slugParam = [[OARequestParameter alloc] initWithName:@"slug" value:slug];
		OARequestParameter *privateParam = [[OARequestParameter alloc] initWithName:@"state" value:private];
		NSArray *params = [NSArray arrayWithObjects:typeParam, captionParam, tweetParam, tagsParam, slugParam, privateParam, nil];
		[typeParam release];
		[captionParam release];
		[tweetParam release];
		[tagsParam release];
		[slugParam release];
		[privateParam release];
		
		[oRequest prepare];
		
		NSString *boundary = @"0xKhTmLbOuNdArY";
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
		[oRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
		
		NSMutableData *body = [NSMutableData data];
		for (OARequestParameter *parameter in params) {
			NSString *param = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
							   boundary, [parameter name], [parameter value]];
			[body appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
		}
		
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"Content-Disposition: form-data; name=\"data\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[self generateImageData]];
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[oRequest setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
		[oRequest setHTTPBody:body];
	}

	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(sendTicket:didFinishWithData:)
																				   didFailSelector:@selector(sendTicket:didFailWithError:)];
	[fetcher start];
	[oRequest release];
	
	// Notify delegate
	[self sendDidStart];
	
	return YES;
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	// TODO better error handling here
	
	if (ticket.didSucceed) {
		[self sendDidFinish];
	}
	else {
		[self handleUnsuccessfulTicket:data];
	}
}

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

- (void)getUserInfo
{
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tumblr.com/v2/user/info"]
																	consumer:consumer
																	   token:accessToken
																	   realm:nil
														   signatureProvider:nil];
	[oRequest setHTTPMethod:@"GET"];
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(getUserInfo:didFinishWithData:)
																				   didFailSelector:@selector(getUserInfo:didFailWithError:)];
	[fetcher start];
	[oRequest release];
}

- (void)getUserInfo:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed) {
		NSError *error = nil;
		NSMutableDictionary *userInfo;
		Class serializator = NSClassFromString(@"NSJSONSerialization");
		if (serializator) {
			userInfo = [serializator JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
		} else {
			userInfo = [[JSONDecoder decoder] mutableObjectWithData:data error:&error];
		}
		
		if (error) {
			SHKLog(@"Error when parsing json tumblr user info request:%@", [error description]);
		}
		[userInfo convertNSNullsToEmptyStrings];
		
		// Only take what we want
		userInfo = [[userInfo objectForKey:@"response"] objectForKey:@"user"];
		
		[[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKTumblrUserInfo];
		
		NSArray *urls = [self getBlogHostNames];
		if (urls) {
			[self optionsEnumerated:urls];
		}
	}
	else {
		[self handleUnsuccessfulTicket:data];
	}
}

- (void)getUserInfo:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	// See if we can show an older list
	NSArray *urls = [self getBlogHostNames];
	if (urls) {
		[self optionsEnumerated:urls];
	}
	else {
		[self sendDidFailWithError:error];
	}
}


#pragma mark -

- (void)handleUnsuccessfulTicket:(NSData *)data
{
	if (SHKDebugShowLogs)
		SHKLog(@"Tumblr Send Error: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	// CREDIT: Oliver Drobnik
	
	NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	// in case our makeshift parsing does not yield an error message
	NSString *errorMessage = @"Unknown Error";
	
	NSScanner *scanner = [NSScanner scannerWithString:string];
	
	// skip until error message
	[scanner scanUpToString:@"\"msg\":\"" intoString:nil];
	
	
	if ([scanner scanString:@"\"msg\":\"" intoString:nil]) {
		// get the message until the closing double quotes
		[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&errorMessage];
	}
	
	
	// this is the error message for revoked access ...?... || removed app from Tumblr
	if ([errorMessage isEqualToString:@"Invalid / used nonce"] || [errorMessage isEqualToString:@"Could not authenticate with OAuth."]) {
		[self shouldReloginWithPendingAction:SHKPendingSend];
		
	} else {
		//when sharing image, and the user removed app permissions there is no JSON response expected above, but XML, which we need to parse. 401 is obsolete credentials -> need to relogin
		if ([[SHKXMLResponseParser getValueForElement:@"status" fromResponse:data] isEqualToString:@"401"]) {
			
			[self shouldReloginWithPendingAction:SHKPendingSend];
			return;
		}
	}
	
	NSError *error = [NSError errorWithDomain:@"Tumblr" code:2 userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
	[self sendDidFailWithError:error];
}

#pragma mark -

- (NSData*) generateImageData
{
	return UIImageJPEGRepresentation(item.image, .9);
}

- (NSArray *)getBlogHostNames
{
	if ([[NSUserDefaults standardUserDefaults] objectForKey:kSHKTumblrUserInfo]) {
		NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKTumblrUserInfo];
		NSMutableArray *urls = [NSMutableArray array];
		NSDictionary *blogs = [userInfo objectForKey:@"blogs"];
		
		for (NSDictionary *blog in blogs) {
			NSString *url = [blog objectForKey:@"url"];
			url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
			url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];
			if ([url hasSuffix:@"/"])
				url = [url substringToIndex:[url length] - 1];
			
			[urls addObject:url];
		}
		
		return urls;
	}
	return nil;
}


#pragma mark -
#pragma mark SHKFormOptionControllerOptionProvider Methods

- (void)optionsEnumerated:(NSArray*)options
{
	NSAssert(curOptionController != nil, @"Any pending requests should have been canceled in SHKFormOptionControllerCancelEnumerateOptions");
	[curOptionController optionsEnumerated:options];
	curOptionController = nil;
}

- (void)optionsEnumerationFailed:(NSError*)error
{
	NSAssert(curOptionController != nil, @"Any pending requests should have been canceled in SHKFormOptionControllerCancelEnumerateOptions");
	[curOptionController optionsEnumerationFailedWithError:error];
	curOptionController = nil;
	
	// See if we can show an older list
	NSArray *urls = [self getBlogHostNames];
	if (urls) {
		[self optionsEnumerated:urls];
	}
}

- (void)SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController*) optionController
{
	NSAssert(curOptionController == nil, @"there should never be more than one picker open.");
	curOptionController = optionController;
	[self getUserInfo];
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController*) optionController
{
	NSAssert(curOptionController == optionController, @"there should never be more than one picker open.");
	curOptionController = nil;
}

@end
