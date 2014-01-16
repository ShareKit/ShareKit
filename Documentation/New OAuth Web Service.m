//  Created by «FULLUSERNAME» on «DATE».

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

/*

 For a step by step guide to creating your service class, start at the top and move down through the comments.
 
*/


«OPTIONALHEADERIMPORTLINE»
#import "SharersCommonHeaders.h"

@implementation «FILEBASENAMEASIDENTIFIER»


#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Name of Web Service");
}


// What types of content can the action handle?

// If the action can handle URLs, uncomment this section
/*
+ (BOOL)canShareURL
{
	return YES;
}
*/

// Does the service need to shorten URL before sharing? If YES, uncomment this section. Do not forget to setup bit.ly credentials in your configurator, otherwise the URL simply will not be shortened
/*
 - (BOOL)requiresShortenedURL {
 
 return YES;
 }
 */

// If the action can handle images, uncomment this section
/*
+ (BOOL)canShareImage
{
	return YES;
}
*/

// If the action can handle text, uncomment this section
/*
+ (BOOL)canShareText
{
	return YES;
}
*/

// If the action can handle files, uncomment this section
/*
+ (BOOL)canShareFile:(SHKFile *)file
{
	return YES;
}
*/

// You should implement this to allow get logged in user info. It is handy if someone needs to show logged-in username (or other info) somewhere in the app. The user info should be saved in a dictionary in user defaults, see SHKFacebook or SHKTwitter. If implemented, uncomment this section. Do not forget override also + (void)logout and delete saved user info from defaults
/*
 + (BOOL)canGetUserInfo
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

// Do you need to dynamically enable/disable the service.  (For example if it only works with specific hardware)? If YES, uncomment this section. Vast majority of services does not need this.
/*
+ (BOOL)canShare
{
	return YES;
}
*/

#pragma mark -
#pragma mark Authentication

- (id)init
{
    self = [super init];
    
	if (self)
	{
        // These config items should be renamed (to match your service name). You have to create corresponding (empty) config methods in DefaultSHKConfigurator. Additionally, make sure, that you also enter valid demo credentials for the demo app in ShareKitDemoConfigurator.m - this greatly simplifies code maintenance and debugging.
		self.consumerKey = SHKCONFIG(yourServiceNameConsumerKey);SHKYourServiceNameConsumerKey;
		self.secretKey = SHKCONFIG(yourServiceNameSecret);SHKYourServiceNameSecretKey;
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(yourServiceCallbackUrl)];
		
		
		// -- //
		
		
		// Edit these to provide the correct urls for each oauth step
	    self.requestURL = [NSURL URLWithString:@"https://api.example.com/get_request_token"];
	    self.authorizeURL = [NSURL URLWithString:@"https://api.example.com/request_auth"];
	    self.accessURL = [NSURL URLWithString:@"https://api.example.com/get_token"];
		
		// Allows you to set a default signature type, uncomment only one
		//self.signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		//self.signatureProvider = [[OAPlaintextSignatureProvider alloc] init];
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
/*
- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	// Here is an example that adds the oauth_verifier value received from the authorize call.
	// authorizeResponseQueryVars is a dictionary that contains the variables sent to the callback url
	[oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}
*/

//if the sharer can get user info (and it should!) override these convenience methods too. Replace example implementation with the one specific for your sharer.
/*
+ (NSString *)username {
 
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKFlickrUserInfo];
    NSString *result = [userInfo findRecursivelyValueForKey:@"_content"];
    return result;
}
+ (void)logout {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFlickrUserInfo];
    [super logout];
}
 */

#pragma mark -
#pragma mark Share Form

// If your action has options or additional information it needs to get from the user,
// use this to create the form that is presented to user upon sharing. You can even set validationBlock to validate user's input for any field setting)
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
    // -if requesting user info : return YES
 
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
	 
    // For more information on OAMutableURLRequest see http://code.google.com/p/oauthconsumer/wiki/UsingOAuthConsumer
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.example.com/share"]
                                                                    consumer:consumer // this is a consumer object already made available to us
                                                                       token:accessToken // this is our accessToken already made available to us
                                                                       realm:nil
                                                           signatureProvider:signatureProvider];
    
    // Set the http method (POST or GET)
    [oRequest setHTTPMethod:@"POST"];
    
    
    // Determine which type of share to do
    switch (item.shareType) {
        case SHKShareTypeURL:
        {
            // Create our parameters
            OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"url" value:SHKEncodeURL(item.URL)];
            OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title" value:SHKEncode(item.title)];
            
            // Add the params to the request
            [oRequest setParameters:[NSArray arrayWithObjects:titleParam, urlParam, nil]];
        }
        case SHKShareTypeFile
        {
            if (self.item.URLContentType == SHKShareContentImage) {
                
                // Create our parameters
                OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"photo"];
                OARequestParameter *captionParam = [[OARequestParameter alloc] initWithName:@"caption" value:item.title];
                
                //Setup the request...
                [params addObjectsFromArray:@[typeParam, captionParam]];
                
                /* bellow lines might help you upload binary data */
                
                //make OAuth signature prior appending the multipart/form-data
                [oRequest prepare];
                
                //create multipart
                [oRequest attachFileWithParameterName:@"data" filename:self.item.filename contentType:self.item.mimeType data:self.item.data];
            }
        }
        default:
            return NO;
            break;
    }
    // Start the request
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];	
    [fetcher start];
    
    // Notify delegate
    [self sendDidStart];
        
    return YES;
}

/* This is a continuation of the example provided in 'send' above.  These methods handle the OAAsynchronousDataFetcher response and should be implemented - your duty is to check the response and decide, if send finished OK, or what kind of error there is. Depending on the result, you should call one of these methods:

 [self sendDidFinish]; (if successful)   
 [self shouldReloginWithPendingAction:SHKPendingSend]; (if credentials saved in app are obsolete - e.g. user might have changed password, or revoked app access - this will prompt for new credentials and silently share after successful login)
 [self shouldReloginWithPendingAction:SHKPendingShare]; (if credentials saved in app are obsolete - e.g. user might have changed password, or revoked app access - this will prompt for new credentials and present share UI dialogue after successful login. This can happen if the service always requires to check credentials prior send request).
 [self sendShowSimpleErrorAlert]; (in case of other error)
 [self sendDidCancel];(in case of user cancelled - you might need this if the service presents its own UI for sharing))
*/

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{	
	if (ticket.didSucceed)
	{
		// The send was successful
		[self sendDidFinish];
	}
	
	else 
	{
		// Handle the error. You can scan the string created from NSData for some result code, or you can use SHKXMLResponseParser. For inspiration look at how existing sharers do this.
		
		// If the error was the result of the user no longer being authenticated, you can reprompt
		// for the login information with:
		[self shouldReloginWithPendingAction:SHKPendingSend];
		
		// Otherwise, all other errors should end with:
		[self sendShowSimpleErrorAlert];
	}
}
- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendShowSimpleErrorAlert];
}

@end
