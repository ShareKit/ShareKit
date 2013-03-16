//
//  SHKInstapaper.m
//  ShareKit
//
//  Created by Sean Murphy on 7/8/10.
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

#import "SHKInstapaper.h"

static NSString * const kInstapaperAuthenticationURL = @"https://www.instapaper.com/api/authenticate";
static NSString * const kInstapaperSharingURL = @"https://www.instapaper.com/api/add";

@interface SHKInstapaper ()
- (void)authFinished:(SHKRequest *)aRequest;
- (void)sendFinished:(SHKRequest *)aRequest;
@end

@implementation SHKInstapaper

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Instapaper");
}

+ (BOOL)canShareURL
{
	return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return YES;
}

#pragma mark -
#pragma mark Authorization

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"Instapaper.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form
{
	// Display an activity indicator
	if (!self.quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
	
	
	// Authorize the user through the server
	NSDictionary *formValues = [form formValues];
	
	NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@",
                       SHKEncode([formValues objectForKey:@"username"]),
                       SHKEncode([formValues objectForKey:@"password"])
                       ];
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:kInstapaperAuthenticationURL]
                                           params:params
                                         delegate:self
                               isFinishedSelector:@selector(authFinished:)
                                           method:@"POST"
                                        autostart:YES] autorelease];
	
	self.self.pendingForm = form;
}

- (void)authFinished:(SHKRequest *)aRequest
{		
	[[SHKActivityIndicator currentIndicator] hide];
	
	if (aRequest.success)
		[self.pendingForm saveForm];
	
	else {
        
        if (aRequest.response.statusCode == 403)
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
  // Instapaper will automatically obtain a title for the URL, so we do not need
  // any other information.
	return nil;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{		
	if ([self validateItem]) {	

        NSString *params = [NSMutableString stringWithFormat:@"url=%@&title=%@&selection=%@&username=%@&password=%@",
                            SHKEncodeURL(self.item.URL),
                            SHKEncode(self.item.title),
                            SHKEncode(SHKFlattenHTML(self.item.text, YES)),
                            SHKEncode([self getAuthValueForKey:@"username"]),
                            SHKEncode([self getAuthValueForKey:@"password"])];
		
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:kInstapaperSharingURL]
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
	if (!aRequest.success) {
		       
        if (aRequest.response.statusCode == 403) {//user changed password
            [self shouldReloginWithPendingAction:SHKPendingSend];
			return;
		}
        else if (aRequest.response.statusCode == 500) {		
            [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"The service encountered an error. Please try again later.")]];
            return;
        }
        
		[self sendShowSimpleErrorAlert];
		return;
	}
    
	[self sendDidFinish];
}

@end
