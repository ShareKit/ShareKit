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

#import "SHKLinkedIn.h"

#import "SharersCommonHeaders.h"
#import "SHKXMLResponseParser.h"

NSString *SHKLinkedInVisibilityCodeKey = @"visibility.code";

// The oauth scope we need to request at LinkedIn
#define SHKLinkedInRequiredScope @"rw_nus"

@implementation SHKLinkedIn

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"LinkedIn");
}

+ (BOOL)canShareURL
{
    return YES;
}

+ (BOOL)canShareText
{
    return YES;
}

#pragma mark -
#pragma mark Authentication

- (id)init
{
	if (self = [super init])
	{		
		self.consumerKey = SHKCONFIG(linkedInConsumerKey);		
		self.secretKey = SHKCONFIG(linkedInSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(linkedInCallbackUrl)];
		
		// -- //
		
	    self.requestURL = [NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/requestToken"];
	    self.authorizeURL = [NSURL URLWithString:@"https://www.linkedin.com/uas/oauth/authorize"];
	    self.accessURL = [NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/accessToken"];
		
		self.signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
	}	
	return self;
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	SHKLog(@"req: %@", authorizeResponseQueryVars);
    [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
	[oRequest setOAuthParameterName:@"oauth_callback" withValue:[self.authorizeCallbackURL absoluteString]];
    
    // We need the rw_nus scope to be able to share messages.
    [oRequest setOAuthParameterName:@"scope" withValue:SHKLinkedInRequiredScope];
}

#pragma mark -
#pragma mark Share Form
- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    NSMutableArray *result = [@[[SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Comment")
                                                                 key:@"text"
                                                                type:SHKFormFieldTypeTextLarge
                                                               start:self.item.text
                                                       maxTextLength:700
                                                               image:nil
                                                     imageTextLength:0
                                                                link:self.item.URL
                                                                file:self.item.file
                                                      allowEmptySend:NO
                                                              select:YES],
                              [SHKFormFieldSettings label:SHKLocalizedString(@"Public")
                                                      key:SHKLinkedInVisibilityCodeKey
                                                     type:SHKFormFieldTypeSwitch
                                                    start:SHKFormFieldSwitchOn]] mutableCopy];
    if (type == SHKShareTypeURL) {
        [result insertObject:[SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title] atIndex:0];
    }
    return result;
}

+ (BOOL)canAutoShare
{
    return NO;
}

#pragma mark -
#pragma mark Implementation

// Send the share item to the server
- (BOOL)send
{	
	if (![self validateItem]) return NO;
	
    // Determine which type of share to do
    if (self.item.shareType == SHKShareTypeText || self.item.shareType == SHKShareTypeURL) // sharing a Text or URL
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
        NSString *comment = [self sanitizeString:self.item.text];

        NSString *visibility;
        BOOL public = [[self.item customValueForKey:SHKLinkedInVisibilityCodeKey] boolValue];
        if (public) {
            visibility = @"anyone";
        } else {
            visibility = @"connections-only";
        }
        
        NSString *submittedUrl;
        if (self.item.shareType == SHKShareTypeURL) {
            
            NSString *submittedTitle = @"";
            if ([self.item.title length]) {
                submittedTitle = [[NSString alloc] initWithFormat:@"<title>%@</title>",[self sanitizeString:self.item.title]];
            }
            NSString *urlString = [self sanitizeString:self.item.URL.absoluteString];
            submittedUrl = [NSString stringWithFormat:@"<content>%@<submitted-url>%@</submitted-url></content>", submittedTitle, urlString];
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
        
        // Notify delegate
        [self sendDidStart];
        
        return YES;
    }
    
    return NO;
}

- (NSString *)sanitizeString:(NSString *)string {
    
    return [[[[string stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"] stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"] stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"] stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
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
        
#ifdef _SHKDebugShowLogs
        NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#endif
        SHKLog(@"%@", responseBody);
        
        // Handle the error
        
        // If the error was the result of the user no longer being authenticated, you can reprompt
        // for the login information with:
        NSString *errorCode = [SHKXMLResponseParser getValueForElement:@"status" fromResponse:data];
        
        // If we receive 401, we're not logged in. If we receive 403, we were logged in before, but didn't
        // yet have the proper privileges, so we force a relogin so linkedin can ask the user the
        // correct privileges.
        if ([errorCode isEqualToString:@"401"] || [errorCode isEqualToString:@"403"]) {
            
            [self shouldReloginWithPendingAction:SHKPendingSend];
            
        } else {
            
            // Otherwise, all other errors should end with:            
            [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"The service encountered an error. Please try again later.")] shouldRelogin:NO]; 
        }
    }
}

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
    [self sendDidFailWithError:error shouldRelogin:NO];
}


@end
