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
#import "JSONKit.h"
#import "SHKConfiguration.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

#define API_DOMAIN  @"http://api.t.sina.com.cn"

static NSString *const kSHKSinaWeiboUserInfo = @"kSHKSinaWeiboUserInfo";

@interface SHKSinaWeibo ()

- (BOOL)prepareItem;
- (BOOL)shortenURL;
- (void)shortenURLFinished:(SHKRequest *)aRequest;
- (BOOL)validateItemAfterUserEdit;
- (void)handleUnsuccessfulTicket:(NSData *)data;

@end

@implementation SHKSinaWeibo

@synthesize xAuth;

- (id)init
{
	if ((self = [super init]))
	{		
		// OAuth
		self.consumerKey = SHKCONFIG(sinaWeiboConsumerKey);		
		self.secretKey = SHKCONFIG(sinaWeiboConsumerSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(sinaWeiboCallbackUrl)];
		
		// xAuth
		self.xAuth = [SHKCONFIG(sinaWeiboUseXAuth) boolValue] ? YES : NO;
		
		
		// -- //
		
		
		// You do not need to edit these, they are the same for everyone
		self.authorizeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/authorize", API_DOMAIN]];
		self.requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/request_token", API_DOMAIN]];
		self.accessURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/oauth/access_token", API_DOMAIN]];
	}	
	return self;
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
#pragma mark Commit Share

- (void)share 
{
	BOOL itemPrepared = [self prepareItem];
	
	//the only case item is not prepared is when we wait for URL to be shortened on background thread. In this case [super share] is called in callback method
	if (itemPrepared) {
		[super share];
	}
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
#pragma mark Authorization

- (void)promptAuthorization
{		
	if (xAuth)
		[super authorizationFormShow]; // xAuth process
	
	else
		[super promptAuthorization]; // OAuth process		
}

+ (void)logout {
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKSinaWeiboUserInfo];
	[super logout];    
}

#pragma mark xAuth

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"weibo.com");
}

+ (NSArray *)authorizationFormFields
{
	if ([SHKCONFIG(sinaWeiboUserID) isEqualToString:@""])
		return [super authorizationFormFields];
	
    NSString *followMeString = [SHKCONFIG(sinaWeiboScreenname) isEqualToString:@""] ? 
        SHKLocalizedString(@"Follow us") : SHKLocalizedString(@"Follow %@", SHKCONFIG(sinaWeiboScreenname));
    
    return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],
			[SHKFormFieldSettings label:followMeString key:@"followMe" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOn],			
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
    else
    {
        if (pendingAction == SHKPendingRefreshToken)
        {
            if (accessToken.sessionHandle != nil)
                [oRequest setOAuthParameterName:@"oauth_session_handle" withValue:accessToken.sessionHandle];
        }
        else
            [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
    }
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (xAuth) 
	{
		if (ticket.didSucceed)
		{
			[item setCustomValue:[[pendingForm formValues] objectForKey:@"followMe"] forKey:@"followMe"];
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

- (void)show
{
    if (item.shareType == SHKShareTypeURL)
	{
		[self showSinaWeiboForm];
	}
	
    else if (item.shareType == SHKShareTypeImage)
	{
		[self showSinaWeiboForm];
	}
	
	else if (item.shareType == SHKShareTypeText)
	{
		[self showSinaWeiboForm];
	}
    
    else if (item.shareType == SHKShareTypeUserInfo)
	{
		[self setQuiet:YES];
		[self tryToSend];
	}
}

- (void)showSinaWeiboForm
{
	SHKFormControllerLargeTextField *rootView = [[SHKFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];	
	
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
	// Check if we should send follow request too
	if (xAuth && [item customBoolForSwitchKey:@"followMe"])
		[self followMe];	
	
	if (![self validateItemAfterUserEdit])
		return NO;
	
	switch (item.shareType) {
			
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

- (void)sendStatus
{
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/statuses/update.json", API_DOMAIN]]
                                                                    consumer:consumer
                                                                       token:accessToken
                                                                       realm:nil
                                                           signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status"
																		 value:[item customValueForKey:@"status"]];
	NSArray *params = [NSArray arrayWithObjects:statusParam, nil];
	[oRequest setParameters:params];
	[statusParam release];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendStatusTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendStatusTicket:didFailWithError:)];	
    
	[fetcher start];
	[oRequest release];
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
	if([item customValueForKey:@"profile_update"]){
		serviceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/account/update_profile_image.json", API_DOMAIN]];
	} else {
		serviceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/statuses/upload.json", API_DOMAIN]];
	}
	
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:serviceURL
																	consumer:consumer
																	   token:accessToken
																	   realm:API_DOMAIN
														   signatureProvider:signatureProvider];
    [oRequest setHTTPMethod:@"POST"];
    [oRequest prepare];
    
	CGFloat compression = 0.9f;
	NSData *imageData = UIImageJPEGRepresentation([item image], compression);
	
	// TODO
	// Note from Nate to creator of sendImage method - This seems like it could be a source of sluggishness.
	// For example, if the image is large (say 3000px x 3000px for example), it would be better to resize the image
	// to an appropriate size (max of img.ly) and then start trying to compress.
	
	while ([imageData length] > 700000 && compression > 0.1) {
		// NSLog(@"Image size too big, compression more: current data size: %d bytes",[imageData length]);
		compression -= 0.1;
		imageData = UIImageJPEGRepresentation([item image], compression);
		
	}
	
	NSString *boundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[oRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	NSMutableData *body = [NSMutableData data];
	NSString *dispKey = @"";
	if([item customValueForKey:@"profile_update"]){
		dispKey = @"Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\"\r\n";
	} else {
		dispKey = @"Content-Disposition: form-data; name=\"pic\"; filename=\"upload.jpg\"\r\n";
	}
    
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[dispKey dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: image/jpg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageData];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	
	if([item customValueForKey:@"profile_update"]){
		// no ops
	} else {
		[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"status\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[item customValueForKey:@"status"] dataUsingEncoding:NSUTF8StringEncoding]];
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
	
	
	[oRequest release];
}

- (void)sendImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	// TODO better error handling here
    SHKLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    
	// NSLog([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	if (ticket.didSucceed) {
		[self sendDidFinish];
		// Finished uploading Image, now need to posh the message and url in sina weibo
		NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSRange startingRange = [dataString rangeOfString:@"<url>" options:NSCaseInsensitiveSearch];
		//NSLog(@"found start string at %d, len %d",startingRange.location,startingRange.length);
		NSRange endingRange = [dataString rangeOfString:@"</url>" options:NSCaseInsensitiveSearch];
		//NSLog(@"found end string at %d, len %d",endingRange.location,endingRange.length);
		
		if (startingRange.location != NSNotFound && endingRange.location != NSNotFound) {
			NSString *urlString = [dataString substringWithRange:NSMakeRange(startingRange.location + startingRange.length, endingRange.location - (startingRange.location + startingRange.length))];
			//NSLog(@"extracted string: %@",urlString);
			[item setCustomValue:[NSString stringWithFormat:@"%@ %@",[item customValueForKey:@"status"],urlString] forKey:@"status"];
			[self sendStatus];
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
	[item setCustomValue:nil forKey:@"followMe"];
    
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/friendships/create/%@.json", API_DOMAIN, SHKCONFIG(sinaWeiboUserID)]]
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
	[oRequest release];
}

@end
