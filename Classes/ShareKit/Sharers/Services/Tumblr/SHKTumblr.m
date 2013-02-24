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
+ (BOOL)canShareText { return YES; }
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

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	[oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	
    NSMutableArray *baseArray = [NSMutableArray arrayWithObjects:
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Title")
                                                         key:@"title"
                                                        type:SHKFormFieldTypeText
                                                       start:self.item.title],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Body")
                                                         key:@"text"
                                                        type:SHKFormFieldTypeText
                                                       start:self.item.text],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag")
                                                         key:@"tags"
                                                        type:SHKFormFieldTypeText
                                                       start:[self.item.tags componentsJoinedByString:@", "]],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Publish")
                                                         key:@"publish"
                                                        type:SHKFormFieldTypeOptionPicker
                                                       start:nil
                                            optionPickerInfo:[@{@"title":SHKLocalizedString(@"Publish type"),
                                                              @"curIndexes":@"-1",
                                                              @"itemsList":@[@"Publish now", @"Draft", @"Add to queue", @"Private"],
                                                              @"itemsValues":@[@"published", @"draft", @"queue", @"private"],
                                                              @"static":[NSNumber numberWithBool:YES],
                                                              @"allowMultiple":[NSNumber numberWithBool:NO]} mutableCopy]
                                    optionDetailLabelDefault:SHKLocalizedString(@"Select publish type")], nil];
    return baseArray;
}
                                 /*
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Is Public")
                                                         key:@"is_public"
                                                        type:SHKFormFieldTypeSwitch
                                                       start:SHKFormFieldSwitchOn],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Is Friend")
                                                         key:@"is_friend"
                                                        type:SHKFormFieldTypeSwitch
                                                       start:SHKFormFieldSwitchOn],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Is Family")
                                                         key:@"is_family"
                                                        type:SHKFormFieldTypeSwitch
                                                       start:SHKFormFieldSwitchOn],
                                 [SHKFormFieldSettings label:SHKLocalizedString(@"Post To Groups")
                                                         key:@"postgroup"
                                                        type:SHKFormFieldTypeOptionPicker
                                                       start:nil
                                            optionPickerInfo:[NSMutableDictionary dictionaryWithObjectsAndKeys:SHKLocalizedString(@"Flickr Groups"), @"title",
                                                              @"-1", @"curIndexes",
                                                              [NSArray array],@"itemsList",
                                                              [NSNumber numberWithBool:NO], @"static",
                                                              [NSNumber numberWithBool:YES], @"allowMultiple",
                                                              self, @"SHKFormOptionControllerOptionProvider",
                                                              nil]
                                    optionDetailLabelDefault:SHKLocalizedString(@"Select Group")],
                                 nil
                                 ];

    
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
	
    OAMutableURLRequest *oRequest = nil;
    NSMutableArray *params = [@[] mutableCopy];
    
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@","] invertedSet];
	NSString *tags = [self tagStringJoinedBy:@"," allowedCharacters:allowedCharacters tagPrefix:nil tagSuffix:nil];
    
    switch (item.shareType) {
            
        case SHKShareTypeUserInfo:
            oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tumblr.com/v2/user/info"]
                                                                            consumer:consumer // this is a consumer object already made available to us
                                                                               token:accessToken // this is our accessToken already made available to us
                                                                               realm:nil
                                                                   signatureProvider:signatureProvider];
            [oRequest setHTTPMethod:@"GET"];
            break;
            
        case SHKShareTypeText:
        {
            NSString *urlString = [[NSString alloc] initWithFormat:@"http://api.tumblr.com/v2/blog/%@/post", @"cocoaminers.tumblr.com"];
            oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                                       consumer:consumer // this is a consumer object already made available to us
                                                          token:accessToken // this is our accessToken already made available to us
                                                          realm:nil
                                              signatureProvider:signatureProvider];
            [urlString release];
            
            [oRequest setHTTPMethod:@"POST"];
            
            OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"text"];
            OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title" value:item.title];
            OARequestParameter *bodyParam = [[OARequestParameter alloc] initWithName:@"body" value:item.text];
            [params addObjectsFromArray:@[typeParam, titleParam, bodyParam]];
            [typeParam release];
            [titleParam release];
            [bodyParam release];
            //OARequestParameter *tweetParam = [[OARequestParameter alloc] initWithName:@"tweet" value:shouldTweet];
            //[tweetParam release];
        }
        default:
            break;
    }
    OARequestParameter *tagsParam = [[OARequestParameter alloc] initWithName:@"tags" value:tags];
    OARequestParameter *publishParam = [[OARequestParameter alloc] initWithName:@"state" value:[self.item customValueForKey:@"publish"]];
    [params addObjectsFromArray:@[tagsParam, publishParam]];
    [tagsParam release];
    [publishParam release];
    [oRequest setParameters:params];
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
