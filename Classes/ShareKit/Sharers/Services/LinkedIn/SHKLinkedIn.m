//
//  SHKLinkedIn.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/22/11.
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
#import "SHKLinkedIn.h"
#import "SHKLinkedInOAMutableURLRequest.h"
#import "SHKLinkedInTextForm.h"

NSString *SHKLinkedInVisibilityCodeKey = @"visibility.code";

@implementation SHKLinkedIn

#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return @"LinkedIn";
}


// What types of content can the action handle?

// If the action can handle URLs, uncomment this section
+ (BOOL)canShareURL
{
    return YES;
}

// If the action can handle images, uncomment this section
/*
 + (BOOL)canShareImage
 {
 return YES;
 }
 */

// If the action can handle text, uncomment this section
+ (BOOL)canShareText
{
    return YES;
}


// If the action can handle files, uncomment this section
/*
 + (BOOL)canShareFile
 {
 return YES;
 }
 */


// Does the service require a login?  If for some reason it does NOT, uncomment this section:
/*
 + (BOOL)requiresAuthentication
 {
 return NO;
 }
 */ 


#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the service.  (For example if it only works with specific hardware)
+ (BOOL)canShare
{
	return YES;
}



#pragma mark -
#pragma mark Authentication

// These defines should be renamed (to match your service name).
// They will eventually be moved to SHKConfig so the user can modify them.

#define SHKYourServiceNameConsumerKey @""	// The consumer key
#define SHKYourServiceNameSecretKey @""		// The secret key
#define SHKYourServiceNameCallbackUrl @""	// The user defined callback url

- (id)init
{
	if (self = [super init])
	{		
		self.consumerKey = SHKCONFIG(linkedInConsumerKey);		
		self.secretKey = SHKCONFIG(linkedInSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(linkedInCallbackUrl)];
		
		// -- //
		
		
		// Edit these to provide the correct urls for each oauth step
	    self.requestURL = [NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/requestToken"];
	    self.authorizeURL = [NSURL URLWithString:@"https://www.linkedin.com/uas/oauth/authorize"];
	    self.accessURL = [NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/accessToken"];
		
		self.signatureProvider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
	}	
	return self;
}

- (void)tokenAccess:(BOOL)refresh
{
	if (!refresh)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Authenticating...")];
	
    SHKLinkedInOAMutableURLRequest *oRequest = [[SHKLinkedInOAMutableURLRequest alloc] initWithURL:accessURL
                                                                                          consumer:consumer
                                                                                             token:(refresh ? accessToken : requestToken)
                                                                                             realm:nil   // our service provider doesn't specify a realm
                                                                                 signatureProvider:signatureProvider // use the default method, HMAC-SHA1
                                                                                          callback:self.authorizeCallbackURL.absoluteString];
	
    [oRequest setHTTPMethod:@"POST"];
	
	[self tokenAccessModifyRequest:oRequest];
	
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(tokenAccessTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(tokenAccessTicket:didFailWithError:)];
	[fetcher start];
	[oRequest release];
}


// If you need to add additional headers or parameters to the request_token request, uncomment this section:
/*
 - (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
 {
 // Here is an example that adds the user's callback to the request headers
 [oRequest setOAuthParameterName:@"oauth_callback" withValue:authorizeCallbackURL.absoluteString];
 }
 */


// If you need to add additional headers or parameters to the access_token request, uncomment this section:
- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
  // Here is an example that adds the oauth_verifier value received from the authorize call.
  // authorizeResponseQueryVars is a dictionary that contains the variables sent to the callback url
  [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}


#pragma mark -
#pragma mark Share Form

- (void)showLinkedInTextForm
{
	SHKLinkedInTextForm *rootView = [[SHKLinkedInTextForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
    if (item.shareType == SHKShareTypeURL) {
        rootView.textView.text = item.title;
    } else {
        rootView.textView.text = item.text;
    }
	
	[self pushViewController:rootView animated:NO];
	
	[[SHK currentHelper] showViewController:self];	
}

- (void)show
{
    if (item.shareType == SHKShareTypeText || item.shareType == SHKShareTypeURL)
	{
		[self showLinkedInTextForm];
	}
}

- (void)sendTextForm:(SHKLinkedInTextForm *)form
{	
    if (item.shareType == SHKShareTypeURL) {
        item.title = form.textView.text;
    } else {
        item.text = form.textView.text;
    }
	[self tryToSend];
}


// If you have a share form the user will have the option to skip it in the future.
// If your form has required information and should never be skipped, uncomment this section.
+ (BOOL)canAutoShare
{
    return NO;
}


#pragma mark -
#pragma mark Implementation

// When an attempt is made to share the item, verify that it has everything it needs, otherwise display the share form
- (BOOL)validateItem
{ 
    if (![super validateItem]) {
        return NO;
    }
    
    if (item.shareType == SHKShareTypeURL && item.title == nil) {
        return NO;
    };
    
    return YES;
}

// Send the share item to the server
- (BOOL)send
{	
	if (![self validateItem])
		return NO;
	
    // Determine which type of share to do
    if (item.shareType == SHKShareTypeText || item.shareType == SHKShareTypeURL) // sharing a Text or URL
    {
        // For more information on OAMutableURLRequest see http://code.google.com/p/oauthconsumer/wiki/UsingOAuthConsumer
        
        OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.linkedin.com/v1/people/~/shares"]
                                                                        consumer:consumer // this is a consumer object already made available to us
                                                                           token:accessToken // this is our accessToken already made available to us
                                                                           realm:nil
                                                               signatureProvider:signatureProvider];
        
        [oRequest setHTTPMethod:@"POST"];
        
        [oRequest prepare]; // Before setting the body, otherwise body will end up in the signature !!!
        
        // TODO use more robust method to escape         
        NSString *comment;
        if (item.shareType == SHKShareTypeURL) {
            comment =[[[[item.title stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
        } else {
            comment =[[[[item.text stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
        }
        
        NSString *visibility = [item customValueForKey:SHKLinkedInVisibilityCodeKey];
        if (visibility == nil) {
            visibility = @"anyone";
        }
        
        NSString *submittedUrl;
        if (item.shareType == SHKShareTypeURL) {
            NSString *urlString = [[[[item.URL.absoluteString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
            submittedUrl = [NSString stringWithFormat:@"<submitted-url>%@</submitted-url>", urlString];
        } else {
            submittedUrl = @"";
        }

        NSString *body = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                          "<share>"
                            "<comment>%@</comment>"
                            "%@"
                            "<visibility>"
                                "<code>%@</code>"
                            "</visibility>"
                          "</share>", comment, submittedUrl, visibility];
        
        [oRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        
        [oRequest setValue:@"text/xml;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];         
        
        // Start the request
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
    
    return NO;
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
    if (ticket.didSucceed)
    {
        // The send was successful
        [self sendDidFinish];
    }
    
    else 
    {
        // Handle the error
        
        // If the error was the result of the user no longer being authenticated, you can reprompt
        // for the login information with:
        // [self sendDidFailShouldRelogin];
        
        // Otherwise, all other errors should end with:
        NSString *responseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSLog(@"%@", responseBody);
        [self sendDidFailWithError:[SHK error:@"Why it failed"] shouldRelogin:NO];
    }
}

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
    [self sendDidFailWithError:error shouldRelogin:NO];
}


@end
