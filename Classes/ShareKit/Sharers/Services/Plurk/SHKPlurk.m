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
	return @"Plurk";
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

- (void)show
{
	if (item.shareType == SHKShareTypeURL)
	{
		[self shortenURL];
	}
  
	else if (item.shareType == SHKShareTypeImage)
	{
		[self uploadImage];
	}
  
	else if (item.shareType == SHKShareTypeText)
	{
		[item setCustomValue:item.text forKey:@"status"];
		[self showPlurkForm];
	}
}

- (void)showPlurkForm
{
	SHKFormControllerLargeTextField *rootView = [[SHKFormControllerLargeTextField alloc] initWithNibName:nil bundle:nil delegate:self];	
	
	// force view to load so we can set textView text
	[rootView view];
	
	rootView.textView.text = [item customValueForKey:@"status"];
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

- (void)shortenURL
{
	if (![SHK connected]) {
		[item setCustomValue:[NSString stringWithFormat:@"%@ (%@)", [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], item.title] forKey:@"status"];
		[self showPlurkForm];
		return;
	}
  
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Shortening URL...")];
  
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[NSMutableString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apikey=%@&longUrl=%@&format=txt",
                                                                        SHKCONFIG(bitLyLogin),
                                                                        SHKCONFIG(bitLyKey),
                                                                        SHKEncodeURL(item.URL)
                                                                        ]]
                                           params:nil
                                         delegate:self
                               isFinishedSelector:@selector(shortenURLFinished:)
                                           method:@"GET"
                                        autostart:YES] autorelease];
}

- (void)shortenURLFinished:(SHKRequest *)aRequest
{
	[[SHKActivityIndicator currentIndicator] hide];
  
	NSString *result = [[aRequest getResult] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  
	if (result == nil || [NSURL URLWithString:result] == nil)
	{
		// TODO - better error message
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Shorten URL Error")
                                 message:SHKLocalizedString(@"We could not shorten the URL.")
                                delegate:nil
                       cancelButtonTitle:SHKLocalizedString(@"Continue")
                       otherButtonTitles:nil] autorelease] show];
    
    [item setCustomValue:[NSString stringWithFormat:@"%@ (%@)", [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], item.text ? item.text : item.title] forKey:@"status"];
	}
  
	else
	{
		///if already a bitly login, use url instead
		if ([result isEqualToString:@"ALREADY_A_BITLY_LINK"])
			result = [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [item setCustomValue:[NSString stringWithFormat:@"%@ (%@)", result, item.text ? item.text : item.title] forKey:@"status"];
	}
  
	[self showPlurkForm];
}


#pragma mark -

- (void)uploadImage
{
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Uploading Image...")];
  
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://www.plurk.com/APP/Timeline/uploadPicture"]
                                                                  consumer:consumer
                                                                     token:accessToken
                                                                     realm:nil
                                                         signatureProvider:nil];
	[oRequest setHTTPMethod:@"POST"];
  
	CGFloat compression = 0.6f;
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
  
	NSString *boundary = @"0XkHtMlBoUnDaRy";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[oRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
  
	NSMutableData *body = [NSMutableData data];
  
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Disposition: form-data; name=\"image\"; filename=\"shk.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageData];
	[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  
	// setting the body of the post to the reqeust
	[oRequest setHTTPBody:body];
  
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
		NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSScanner *scanner = [NSScanner scannerWithString:dataString];
		if ([scanner scanString:@"{\"full\": \"" intoString:nil]) {
      NSString *urlString = nil;
			[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\","] intoString:&urlString];
      urlString = [urlString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
			[item setCustomValue:[NSString stringWithFormat:@"%@ %@", item.title, urlString] forKey:@"status"];
			[self showPlurkForm];
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
	NSString *status = [item customValueForKey:@"status"];
	return status != nil && status.length > 0 && status.length <= 140;
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
                                                                       value:[item customValueForKey:@"status"]];
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
	// TODO better error handling here
  
	if (ticket.didSucceed)
		[self sendDidFinish];
  
	else
	{
		if (SHKDebugShowLogs)
			SHKLog(@"Plurk Send Status Error: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    
		// CREDIT: Oliver Drobnik
    
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    
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
    
		NSError *error = [NSError errorWithDomain:@"Plurk" code:2 userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
		// this is the error message for revoked access
		if ([errorMessage isEqualToString:@"Invalid / used nonce"] || [errorMessage isEqualToString:@"Could not authenticate with OAuth."])
		{
			[self sendDidFailWithError:error shouldRelogin:YES];
		}
		else
		{
			[self sendDidFailWithError:error];
		}
	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

@end