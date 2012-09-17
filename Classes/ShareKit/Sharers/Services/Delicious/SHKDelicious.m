//
//  SHKDelicious.m
//  ShareKit
//
//  Created by saturngod on 11 Jan 2012

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

#import "SHKDelicious.h"
#import "SHKXMLResponseParser.h"

/**
 Private helper methods
 */
@interface SHKDelicious ()
- (void)authFinished:(SHKRequest *)aRequest;
- (void)sendFinished:(SHKRequest *)aRequest;
@end

@implementation SHKDelicious



#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Delicious";
}

+ (BOOL)canShareURL
{
	return YES;
}


#pragma mark -
#pragma mark Authorization

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create an account at %@", @"http://delicious.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form
{
	// Display an activity indicator	
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
	
	
	// Authorize the user through the server
	NSDictionary *formValues = [form formValues];
	
	NSString *password = [SHKEncode([formValues objectForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:
													[NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/get",
													 SHKEncode([formValues objectForKey:@"username"]),
													 password
													 ]]
											params:nil
										  delegate:self
								isFinishedSelector:@selector(authFinished:)
											method:@"GET"
										 autostart:YES] autorelease];
	
	self.pendingForm = form;
}

- (void)authFinished:(SHKRequest *)aRequest
{	
	// Hide the activity indicator
	[[SHKActivityIndicator currentIndicator] hide];
	
	if (aRequest.success)
	{
		[pendingForm saveForm];
	}
    else
    {    
        if (aRequest.response.statusCode == 401)
        {
            [self authShowBadCredentialsAlert];
        }
        else
        {
            [self authShowOtherAuthorizationErrorAlert];
        }   
    }
	[self authDidFinish:aRequest.success];
}


#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	if (type == SHKShareTypeURL)
		return [NSArray arrayWithObjects:
				[SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:item.title],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag") key:@"tags" type:SHKFormFieldTypeText start:[item.tags componentsJoinedByString:@", "]],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Notes") key:@"text" type:SHKFormFieldTypeText start:item.text],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Shared") key:@"shared" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOff],
				nil];
	
	return nil;
}



#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	if ([self validateItem])
	{
        NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
        [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];

		NSString *password = [SHKEncode([self getAuthValueForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        NSString* address =[NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/v1/posts/add?url=%@&description=%@&tags=%@&extended=%@&shared=%@",
                        SHKEncode([self getAuthValueForKey:@"username"]),
                        password,
                        SHKEncodeURL(item.URL),
                        SHKEncode(item.title),
                        SHKEncode([self tagStringJoinedBy:@" " allowedCharacters:allowedCharacters tagPrefix:nil]),
                        SHKEncode(item.text),
                        [item customBoolForSwitchKey:@"shared"]?@"yes":@"no"
                        ];
    
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:address]
												params:nil
											  delegate:self
									isFinishedSelector:@selector(sendFinished:)
												method:@"GET"
											 autostart:YES] autorelease];
		
		
		// Notify delegate
		[self sendDidStart];
		
		return YES;
	}
	
	return NO;
}

- (void)sendFinished:(SHKRequest *)aRequest
{	
	NSString *responseResultCode = [SHKXMLResponseParser getValueForElement:@"code" fromResponse:aRequest.data];
        
    if ([responseResultCode isEqualToString:@"done"]) {
        
        [self sendDidFinish];

    } else {
        
        if (aRequest.response.statusCode == 401){ //user changed password
        
            [self shouldReloginWithPendingAction:SHKPendingSend];        
        
        } else {
            
            [self sendShowSimpleErrorAlert];
        }
    }
}

@end
