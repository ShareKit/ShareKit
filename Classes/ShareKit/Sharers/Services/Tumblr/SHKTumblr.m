//
//  SHKTumblr.m
//  ShareKit
//
//  Created by Vilem Kurz on 24. 2. 2013

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

#import "SHKTumblr.h"
#import "SHKConfiguration.h"
#import "JSONKit.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

NSString * const kSHKTumblrUserInfo = @"kSHKTumblrUserInfo";

@implementation SHKTumblr

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle { return @"Tumblr"; }

//+ (BOOL)canShareURL { return YES; }
//+ (BOOL)canShareImage { return YES; }
//+ (BOOL)canShareText { return YES; }
+ (BOOL)canGetUserInfo { return YES; }

#pragma mark -
#pragma mark Authentication

- (id)init
{
	if (self = [super init])
	{		
		self.consumerKey = SHKCONFIG(tumblrConsumerKey);;		
		self.secretKey = SHKCONFIG(tumblrSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(tumblrCallbackUrl)];
		
	    self.requestURL = [NSURL URLWithString:@"http://www.tumblr.com/oauth/request_token"];
	    self.authorizeURL = [NSURL URLWithString:@"http://www.tumblr.com/oauth/authorize"];
	    self.accessURL = [NSURL URLWithString:@"http://www.tumblr.com/oauth/access_token"];
		
		self.signatureProvider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
	}	
	return self;
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

// If your action has options or additional information it needs to get from the user,
// use this to create the form that is presented to user upon sharing.
/*
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	// See http://getsharekit.com/docs/#forms for documentation on creating forms
	
	if (type == SHKShareTypeURL)
	{
		// An example form that has a single text field to let the user edit the share item's title
		return [NSArray arrayWithObjects:
				[SHKFormFieldSettings label:@"Title" key:@"title" type:SHKFormFieldTypeText start:item.title],
				nil];
	}
	
	else if (type == SHKShareTypeImage)
	{
		// return a form if required when sharing an image
		return nil;		
	}
	
	else if (type == SHKShareTypeText)
	{
		// return a form if required when sharing text
		return nil;		
	}
	
	else if (type == SHKShareTypeFile)
	{
		// return a form if required when sharing a file
		return nil;		
	}
	
	return nil;
}
*/

// If you have a share form the user will have the option to skip it in the future.
// If your form has required information and should never be skipped, uncomment this section.

/*
+ (BOOL)canAutoShare
{
	return NO;
}
 */

// Optionally validate the user input on the share form. You should override (uncomment) this only if you need to validate any data before sending.
/*
 - (void)shareFormValidate:(SHKCustomFormController *)form
 {
 You can get a dictionary of the field values from [form formValues]
 
 You should perform one of the following actions:
 
 1.	Save the form - If everything is correct call
 
 [form saveForm]
 
 2.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
 }
 */


#pragma mark -
#pragma mark Implementation

// When an attempt is made to share the item, verify that it has everything it needs, otherwise display the share form
/*
- (BOOL)validateItem
{ 
	// The super class will verify that:
	// -if sharing a url	: item.url != nil
	// -if sharing an image : item.image != nil
	// -if sharing text		: item.text != nil
	// -if sharing a file	: item.data != nil
 
	return [super validateItem];
}
*/

// Send the share item to the server
- (BOOL)send
{	
	if (![self validateItem])
		return NO;
	
	/*
	 Enter the necessary logic to share the item here.
	 
	 The shared item and relevant data is in self.item
	 // See http://getsharekit.com/docs/#sending
	 
	 --
	 
	 A common implementation looks like:
	 	 
	 -  Send a request to the server
	 -  call [self sendDidStart] after you start your action
	 -  after the action completes, handle the response in didFinishSelector: or didFailSelector: methods.	 */ 
	
	// Here is an example.  
	// This example is for a service that can share a URL
	 
	// Determine which type of share to do
    
    OAMutableURLRequest *oRequest = nil;
    
    switch (item.shareType) {
        case SHKShareTypeUserInfo:
        {
            oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tumblr.com/v2/user/info"]
                                                                            consumer:consumer // this is a consumer object already made available to us
                                                                               token:accessToken // this is our accessToken already made available to us
                                                                               realm:nil
                                                                   signatureProvider:signatureProvider];
            [oRequest setHTTPMethod:@"GET"];
            break;
        }
        default:
            break;
    }
    
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

    /*
	if (item.shareType == SHKShareTypeURL) // sharing a URL
	{
		// For more information on OAMutableURLRequest see http://code.google.com/p/oauthconsumer/wiki/UsingOAuthConsumer
		
		OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"api.tumblr.com/v2/user/info"]
																		consumer:consumer // this is a consumer object already made available to us
																		   token:accessToken // this is our accessToken already made available to us
																		   realm:nil
															   signatureProvider:signatureProvider];
		
		// Set the http method (POST or GET)
		[oRequest setHTTPMethod:@"POST"];
		
		
		// Create our parameters
		OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"url"
																		  value:SHKEncodeURL(item.URL)];
		
		OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title"
																		   value:SHKEncode(item.title)];
		
		// Add the params to the request
		[oRequest setParameters:[NSArray arrayWithObjects:titleParam, urlParam, nil]];
		[urlParam release];
		[titleParam release];
		
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
*/

/* This is a continuation of the example provided in 'send' above.  These methods handle the OAAsynchronousDataFetcher response and should be implemented - your duty is to check the response and decide, if send finished OK, or what kind of error there is. Depending on the result, you should call one of these methods:

 [self sendDidFinish]; (if successful)   
 [self shouldReloginWithPendingAction:SHKPendingSend]; (if credentials saved in app are obsolete - e.g. user might have changed password, or revoked app access - this will prompt for new credentials and silently share after successful login)
 [self shouldReloginWithPendingAction:SHKPendingShare]; (if credentials saved in app are obsolete - e.g. user might have changed password, or revoked app access - this will prompt for new credentials and present share UI dialogue after successful login. This can happen if the service always requires to check credentials prior send request).
 [self sendShowSimpleErrorAlert]; (in case of other error)
 [self sendDidCancel];(in case of user cancelled - you might need this if the service presents its own UI for sharing))
*/

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{	
	if (ticket.didSucceed) {
		
		switch (self.item.shareType) {
            case SHKShareTypeUserInfo:
            {
                NSError *error = nil;
                NSMutableDictionary *userInfo;
                Class serializator = NSClassFromString(@"NSJSONSerialization");
                if (serializator) {
                    userInfo = [serializator JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                } else {
                    userInfo = [[JSONDecoder decoder] mutableObjectWithData:data error:&error];
                }
                
                if (error) {
                    SHKLog(@"Error when parsing json user info request:%@", [error description]);
                }
                
                [userInfo convertNSNullsToEmptyStrings];
                [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKTumblrUserInfo];
            
                break;
            }
            default:
                break;
        }
        
		[self sendDidFinish];
		
	} else {
		
		
        if (ticket.response.statusCode == 401) {
            
            //user revoked acces, ask access again
            [self shouldReloginWithPendingAction:SHKPendingSend];
            
        } else {
            
            SHKLog(@"Tumblr send finished with error:%@", [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease]);
            [self sendShowSimpleErrorAlert];
        }

	}
}
- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	SHKLog(@"Tumblr send failed with error:%@", [error description]);
    [self sendShowSimpleErrorAlert];
}

@end
