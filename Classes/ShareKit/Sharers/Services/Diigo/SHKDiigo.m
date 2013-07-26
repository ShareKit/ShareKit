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

#import "SHKDiigo.h"

#import "SharersCommonHeaders.h"
#import "SHKRequest.h"

@implementation SHKDiigo

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Diigo");
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

- (FormControllerCallback)authorizationFormValidate
{
	__weak typeof(self) weakSelf = self;
    
    FormControllerCallback result = ^ (SHKFormController *form) {
        
        // Display an activity indicator
        if (!weakSelf.quiet)
            [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
        
        weakSelf.pendingForm = form;
        
        // Authorize the user through the server
        NSDictionary *formValues = [form formValues];
        NSString *password = [SHKEncode([formValues objectForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
        
        [SHKRequest startWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%@@secure.diigo.com/api/v2/bookmarks?key=%@&count=1&user=%@",
                                                       SHKEncode([formValues objectForKey:@"username"]),
                                                       password,
                                                       SHKCONFIG(diigoKey),
                                                       SHKEncode([formValues objectForKey:@"username"])
                                                       ]]
                          params:nil
                          method:@"GET"
                      completion:^ (SHKRequest *request) {
                          
                          // Hide the activity indicator
                          [[SHKActivityIndicator currentIndicator] hide];
                          
                          if (request.success)
                          {
                              [weakSelf.pendingForm saveForm];
                          }
                          else
                          {
                              if (request.response.statusCode == 401)
                              {
                                  [weakSelf authShowBadCredentialsAlert];
                              }
                              else
                              {
                                  [weakSelf authShowOtherAuthorizationErrorAlert];
                              }
                              SHKLog(@"%@", [request description]);
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

    NSMutableCharacterSet *allowedCharacters = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowedCharacters formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    [allowedCharacters removeCharactersInString:@","];
    NSString *params = [NSMutableString stringWithFormat:@"key=%@&url=%@&title=%@&tags=%@&desc=%@&shared=%@",SHKCONFIG(diigoKey),SHKEncodeURL(self.item.URL),SHKEncode(self.item.title),SHKEncode([self tagStringJoinedBy:@"," allowedCharacters:allowedCharacters tagPrefix:nil tagSuffix:nil]),SHKEncode(self.item.text),[self.item customBoolForSwitchKey:@"shared"]?@"yes":@"no"];
    
    NSString *password = [SHKEncode([self getAuthValueForKey:@"password"]) stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    
    NSString* address =[NSString stringWithFormat:@"https://%@:%@@secure.diigo.com/api/v2/bookmarks",
                        SHKEncode([self getAuthValueForKey:@"username"]),
                        password];
    
    [SHKRequest startWithURL:[NSURL URLWithString:address]
                      params:params
                      method:@"POST"
                  completion:^ (SHKRequest *request) {
                      
                      if (request.success)
                      {
                          [self sendDidFinish];
                      }
                      else
                      {
                          if (request.response.statusCode == 401)
                          {
                              [self shouldReloginWithPendingAction:SHKPendingSend];
                          }
                          else
                          {        
                              [self sendShowSimpleErrorAlert];
                          }
                          SHKLog(@"Share failed with error:%@", [request description]);
                      }
                  }];
    
    // Notify delegate
    [self sendDidStart];
    return YES;
}

@end
