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

#import "SharersCommonHeaders.h"
#import "SHKRequest.h"

static NSString * const kInstapaperAuthenticationURL = @"https://www.instapaper.com/api/authenticate";
static NSString * const kInstapaperSharingURL = @"https://www.instapaper.com/api/add";

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
#pragma mark Authorization

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"Instapaper.com");
}

- (FormControllerCallback)authorizationFormValidate
{
	__weak typeof(self) weakSelf = self;
    
    FormControllerCallback result = ^(SHKFormController *form) {
        
        // Display an activity indicator
        if (!weakSelf.quiet)
            [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
        
        weakSelf.pendingForm = form;
        
        // Authorize the user through the server
        NSDictionary *formValues = [form formValues];
        
        NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@",
                            SHKEncode([formValues objectForKey:@"username"]),
                            SHKEncode([formValues objectForKey:@"password"])
                            ];
        
        [SHKRequest startWithURL:[NSURL URLWithString:kInstapaperAuthenticationURL]
                          params:params
                          method:@"POST"
                      completion:^ (SHKRequest *request) {
                         
                          [[SHKActivityIndicator currentIndicator] hide];
                          
                          if (request.success)
                              [weakSelf.pendingForm saveForm];
                          
                          else {
                              
                              if (request.response.statusCode == 403)
                              {
                                  [weakSelf authShowBadCredentialsAlert];
                              }
                              else
                              {
                                  [weakSelf authShowOtherAuthorizationErrorAlert];
                              }
                              SHKLog(@"auth error: %@", [request description]);
                          }
                          [weakSelf authDidFinish:request.success];
                      }];
    };
    return result;
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
	if (![self validateItem]) return NO;
    
    NSString *params = [NSMutableString stringWithFormat:@"url=%@&title=%@&selection=%@&username=%@&password=%@",
                        SHKEncodeURL(self.item.URL),
                        SHKEncode(self.item.title),
                        SHKEncode(SHKFlattenHTML(self.item.text, YES)),
                        SHKEncode([self getAuthValueForKey:@"username"]),
                        SHKEncode([self getAuthValueForKey:@"password"])];
    
    [SHKRequest startWithURL:[NSURL URLWithString:kInstapaperSharingURL]
                      params:params
                      method:@"POST"
                  completion:^ (SHKRequest *request) {
                      
                      if (request.success) {
                          
                          [self sendDidFinish];
                          
                      } else {
                          
                          if (request.response.statusCode == 403) {//user changed password
                              
                              [self shouldReloginWithPendingAction:SHKPendingSend];
                              
                          } else if (request.response.statusCode == 500) {
                              
                              [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"The service encountered an error. Please try again later.")]];
                              
                          } else {
                              
                              [self sendShowSimpleErrorAlert];
                          }
                          SHKLog(@"error during share:%@", [request description]);
                      }
                  }];
    
    // Notify delegate
    [self sendDidStart];
    
    return YES;
}

@end
