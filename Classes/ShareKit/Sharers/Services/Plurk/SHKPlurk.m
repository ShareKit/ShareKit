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
#import "SHKConfiguration.h"

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

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
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


#pragma mark -
#pragma mark UI Implementation

//TODO change form to normal form controller and add type of plurk (is, shares, etc) option controller. This should be done after shkformcontroller can have type large text field.
- (void)show
{
	if (self.item.shareType == SHKShareTypeURL)
	{
        [self.item setCustomValue:[NSString stringWithFormat:@"%@ (%@)", [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.item.title] forKey:@"status"];
        [self showPlurkForm];
	}
  
	else if (self.item.shareType == SHKShareTypeImage)
	{
		[self uploadImage];
	}
  
	else if (self.item.shareType == SHKShareTypeText)
	{
		[self.item setCustomValue:self.item.text forKey:@"status"];
		[self showPlurkForm];
	}
}

- (void)showPlurkForm
{
	SHKFormControllerLargeTextField *rootView = [[SHKFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];	
	
	// force view to load so we can set textView text
	[rootView view];
	
	rootView.text = [self.item customValueForKey:@"status"];
  rootView.maxTextLength = 210;
	rootView.image = self.item.image;
  
  self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,self);
	
	[self pushViewController:rootView animated:NO];
  [rootView release];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)sendForm:(SHKFormControllerLargeTextField *)form
{
	[self.item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
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
	[oRequest release];
}

- (void)uploadImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	[[SHKActivityIndicator currentIndicator] hide];
  
  if (SHKDebugShowLogs) {
    SHKLog(@"Plurk Upload Picture Status Code: %d", [ticket.response statusCode]);
    SHKLog(@"Plurk Upload Picture Error: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
  }
  
	if (ticket.didSucceed) {
		// Finished uploading Image, now need to posh the message and url in twitter
        NSError *error = nil;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
		if ([response objectForKey:@"full"]) {
			NSString *urlString = [response objectForKey:@"full"];
			[self.item setCustomValue:[NSString stringWithFormat:@"%@ %@", self.item.title, urlString] forKey:@"status"];
			[self showPlurkForm];
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
	[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Request Error")
                               message:SHKLocalizedString(@"There was an error while sharing")
                              delegate:nil
                     cancelButtonTitle:SHKLocalizedString(@"Continue")
                     otherButtonTitles:nil] autorelease] show];
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)validate
{
	NSString *status = [self.item customValueForKey:@"status"];
	return status != nil && status.length > 0 && status.length <= 210;
}

- (BOOL)send
{
	if (![self validate])
		[self show];
  
	else
	{
    [self sendStatus];
    
		// Notify delegate
		[self sendDidStart];
    
		return YES;
	}
  
	return NO;
}

- (void)sendStatus
{
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.plurk.com/APP/Timeline/plurkAdd"]
                                                                  consumer:consumer
                                                                     token:accessToken
                                                                     realm:nil
                                                         signatureProvider:nil];
  
	[oRequest setHTTPMethod:@"POST"];
  
	OARequestParameter *qualifierParam = [[OARequestParameter alloc] initWithName:@"qualifier"
                                                                          value:@"shares"];
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"content"
                                                                       value:[self.item customValueForKey:@"status"]];
	NSArray *params = [NSArray arrayWithObjects:qualifierParam, statusParam, nil];
	[oRequest setParameters:params];
  [qualifierParam release];
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
	if (ticket.didSucceed)
		[self sendDidFinish];
  
	else
	{
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