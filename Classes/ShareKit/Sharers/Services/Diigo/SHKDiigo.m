//
//  SHKDiigo.m
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
#import "SHKConfiguration.h"
#import "SHKDiigo.h"

/**
 Private helper methods
 */
@interface SHKDiigo ()
- (void)authFinished:(SHKRequest *)aRequest;
- (void)sendFinished:(SHKRequest *)aRequest;
@end

@implementation SHKDiigo



#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Diigo";
}

+ (BOOL)canShareURL
{
	return YES;
}


#pragma mark -
#pragma mark Authorization

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create an account at %@", @"http://www.diigo.com");
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
													[NSString stringWithFormat:@"https://%@:%@@secure.diigo.com/api/v2/bookmarks?key=%@&count=1&user=%@",
													 SHKEncode([formValues objectForKey:@"username"]),
													 password,SHKCONFIG(diigoKey),SHKEncode([formValues objectForKey:@"username"])
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
  else {
    NSString *errorMessage = nil;
    if (aRequest.response.statusCode == 401)
      errorMessage = SHKLocalizedString(@"Sorry, %@ did not accept your credentials. Please try again.", [[self class] sharerTitle]);
    else
      errorMessage = SHKLocalizedString(@"Sorry, %@ encountered an error. Please try again.", [[self class] sharerTitle]);
    
    [[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Login Error")
                                 message:errorMessage
                                delegate:nil
                       cancelButtonTitle:SHKLocalizedString(@"Close")
                       otherButtonTitles:nil] autorelease] show];
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
				[SHKFormFieldSettings label:SHKLocalizedString(@"Tags") key:@"tags" type:SHKFormFieldTypeText start:item.tags],
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
    
    NSString *params = [NSMutableString stringWithFormat:@"key=%@&url=%@&title=%@&tags=%@&desc=%@&shared=%@",SHKCONFIG(diigoKey),SHKEncodeURL(item.URL),SHKEncode(item.title),SHKEncode(item.tags),SHKEncode(item.text),[item customBoolForSwitchKey:@"shared"]?@"yes":@"no"];
    
    
		NSString *password = [SHKEncode([self getAuthValueForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    
    NSString* address =[NSString stringWithFormat:@"https://%@:%@@secure.diigo.com/api/v2/bookmarks",
                        SHKEncode([self getAuthValueForKey:@"username"]),
                        password];
    
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:address]
												params:params
											  delegate:self
									isFinishedSelector:@selector(sendFinished:)
												method:@"POST"
											 autostart:YES] autorelease];
		
		
		// Notify delegate
		[self sendDidStart];
		
		return YES;
	}
	
	return NO;
}

- (void)sendFinished:(SHKRequest *)aRequest
{	
  //should use json kit for respond
	if (aRequest.success)
	{
		if ([[aRequest getResult] rangeOfString:@"bookmark"].location != NSNotFound)
		{
			[self sendDidFinish];
			return;
		}
	} else if (aRequest.response.statusCode == 401) {
        
        [self shouldReloginWithPendingAction:SHKPendingSend]; 
        return;
    }
	
	[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was an error saving to @%", [[self class] sharerTitle])]];		
}

@end
