//
//  SHKPinboard.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

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

#import "SHKPinboard.h"

#import "SharersCommonHeaders.h"
#import "SHKRequest.h"

@implementation SHKPinboard

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Pinboard");
}

+ (BOOL)canShareURL
{
	return YES;
}

#pragma mark -
#pragma mark Authorization

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create an account at %@", @"http://pinboard.in");
}

- (FormControllerCallback)authorizationFormValidate
{
    __weak typeof(self) weakSelf = self;
    FormControllerCallback result = ^(SHKFormController *form) {
        
        // Display an activity indicator
        [weakSelf displayActivity:SHKLocalizedString(@"Logging In...")];
        
        weakSelf.pendingForm = form;
        
        // Authorize the user through the server
        NSDictionary *formValues = [form formValues];
        NSString *password = [SHKEncode([formValues objectForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/posts/get", SHKEncode([formValues objectForKey:@"username"]), password]];

        [SHKRequest startWithURL:url params:nil method:@"POST" completion:^ (SHKRequest *request) {
            
            [self hideActivityIndicator];
            
            if (request.success)
            {
                [weakSelf.pendingForm saveForm];
            }
            else
            {
                if (request.response.statusCode == 401) {
                    
                    [weakSelf authShowBadCredentialsAlert];
                }
                else
                {
                    [weakSelf authShowOtherAuthorizationErrorAlert];

                }
                //SHKLog(@"Pinboard auth failed with response:%@", [request description]);
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
	if (type == SHKShareTypeURL)
		return [NSArray arrayWithObjects:
				[SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag") key:@"tags" type:SHKFormFieldTypeText start:[self.item.tags componentsJoinedByString:@", "]],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Notes") key:@"text" type:SHKFormFieldTypeText start:self.item.text],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Shared") key:@"shared" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOff],
				nil];
	
	return nil;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	if (![self validateItem]) return NO;
    
    NSString *password = [SHKEncode([self getAuthValueForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    
    [SHKRequest startWithURL:[NSURL URLWithString:
                              [NSString stringWithFormat:@"https://%@:%@@api.pinboard.in/v1/posts/add?url=%@&description=%@&tags=%@&extended=%@&shared=%@",
                               SHKEncode([self getAuthValueForKey:@"username"]),
                               password,
                               SHKEncodeURL(self.item.URL),
                               SHKEncode(self.item.title),
                               SHKEncode([self tagStringJoinedBy:@"," allowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@" ,"] invertedSet] tagPrefix:nil tagSuffix:nil]),
                               SHKEncode(self.item.text),
                               [self.item customBoolForSwitchKey:@"shared"]?@"yes":@"no"
                               ]]
                      params:nil
                      method:@"GET"
                  completion:^ (SHKRequest *request) {
                      
                      if (request.success) {
                          
                          [self sendDidFinish];
                          
                      } else {
                          
                          if (request.response.statusCode == 401)
                          {
                              [self shouldReloginWithPendingAction:SHKPendingSend];
                              
                          } else {
                              
                              [self sendShowSimpleErrorAlert];
                              SHKLog(@"Share failed with error:%@", [request description]);
                          }
                      }
                  }];
    
    // Notify delegate
    [self sendDidStart];
    return YES;
}

@end