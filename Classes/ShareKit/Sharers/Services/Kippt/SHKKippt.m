//
//  SHKKippt.m
//  ShareKit
//

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


#import "SHKKippt.h"

#import "SharersCommonHeaders.h"
#import "SHKRequest.h"
#import "Debug.h"

#import <objc/runtime.h>

// -- Constants --

NSString *kAccountURL = @"https://kippt.com/api/account/";
NSString *kListsURL = @"https://kippt.com/api/lists/?limit=0";
NSString *kNewClipURL = @"https://kippt.com/api/clips/";

// -- For HTTP Basic Auth --

static char *alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

NSString *base64(NSData *plainText) {
    int encodedLength = (((([plainText length] % 3) + [plainText length]) / 3) * 4) + 1;
    unsigned char *outputBuffer = malloc(encodedLength);
    unsigned char *inputBuffer = (unsigned char *)[plainText bytes];

    NSInteger i;
    NSInteger j = 0;
    int remain;

    for(i = 0; i < [plainText length]; i += 3) {
        remain = [plainText length] - i;
        
        outputBuffer[j++] = alphabet[(inputBuffer[i] & 0xFC) >> 2];
        outputBuffer[j++] = alphabet[((inputBuffer[i] & 0x03) << 4) | 
                                     ((remain > 1) ? ((inputBuffer[i + 1] & 0xF0) >> 4): 0)];
        
        if(remain > 1)
            outputBuffer[j++] = alphabet[((inputBuffer[i + 1] & 0x0F) << 2)
                                         | ((remain > 2) ? ((inputBuffer[i + 2] & 0xC0) >> 6) : 0)];
            else 
                outputBuffer[j++] = '=';
                
                if(remain > 2)
                    outputBuffer[j++] = alphabet[inputBuffer[i + 2] & 0x3F];
                    else
                        outputBuffer[j++] = '=';            
                        }

    outputBuffer[j] = 0;

    NSString *result = [NSString stringWithCString:(const char*)outputBuffer encoding:NSStringEncodingConversionAllowLossy];
    free(outputBuffer);

    return result;
}

@interface SHKKippt ()

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *password;

@end

@implementation SHKKippt

- (void)sendRequest:(NSString *)url params:(NSString *)params method:(NSString *)method completion:(RequestCallback)completion
{
    // Send request
    SHKRequest *request = [[SHKRequest alloc] initWithURL:[NSURL URLWithString:url]
                                                   params:params
                                                   method:method
                                               completion:completion];
    
    if (!self.username || !self.password) {
        self.username = [self getAuthValueForKey:@"username"];
        self.password = [self getAuthValueForKey:@"password"];
    }
    
    // Basic Auth -- credit: http://stackoverflow.com/a/9468371
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64([authStr dataUsingEncoding:NSUTF8StringEncoding])];
    
    NSDictionary *headers = [[NSDictionary alloc] initWithObjectsAndKeys:authValue, @"Authorization", nil];
    request.headerFields = headers;
    [request start];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Kippt");
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canAutoShare
{
    return NO;
}

#pragma mark -
#pragma mark Authorization

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"kippt.com");
}

- (FormControllerCallback)authorizationFormValidate
{
	__weak typeof(self) weakSelf = self;
    
    FormControllerCallback result = ^ (SHKFormController *form) {
        
        // Display an activity indicator
        if (!weakSelf.quiet) {
            [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging in...")];
        }
        
        weakSelf.pendingForm = form;

        // Authorize the user through the server
        NSDictionary *formValues = [form formValues];
        
        // Remember user/pass
        weakSelf.username = [formValues objectForKey:@"username"];
        weakSelf.password = [formValues objectForKey:@"password"];
        
        // Send request
        [weakSelf sendRequest:kAccountURL params:nil method:@"POST" completion:^ (SHKRequest *request) {
            
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
	if (type == SHKShareTypeURL) {
        
        // Placeholder list
        NSMutableArray *lists = [NSMutableArray array];
        [lists addObject:@"Inbox"];
        
		return [NSArray arrayWithObjects:
				[SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Notes") key:@"notes" type:SHKFormFieldTypeText start:self.item.text],
				[SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"List")
                                                    key:@"list"
                                                   type:SHKFormFieldTypeOptionPicker
                                                  start:nil
                                            pickerTitle:SHKLocalizedString(@"List")
                                        selectedIndexes:[[NSMutableIndexSet alloc] initWithIndex:0]
                                          displayValues:lists
                                             saveValues:nil
                                          allowMultiple:NO
                                           fetchFromWeb:YES
                                               provider:self], nil];}
	return nil;
}

#pragma mark -
#pragma mark SHKFormOptionControllerOptionProvider

- (void)SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController *)optionController
{
    self.curOptionController = optionController;
    
    // This is our cue to fire a request
    [self sendRequest:kListsURL params:nil method:@"GET" completion:^(SHKRequest *request) {
        
        if (request.response.statusCode != 200) {
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Failed to fetch lists." forKey:NSLocalizedDescriptionKey];
            NSError *err = [NSError errorWithDomain:@"KPT" code:1 userInfo:userInfo];
            [self.curOptionController optionsEnumerationFailedWithError:err];
            
        } else {
            
            NSError *error = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:request.data options:NSJSONReadingMutableContainers error:&error];
            NSMutableArray *displayValues = [@[] mutableCopy];
            NSMutableArray *saveValues = [@[] mutableCopy];
            for (NSDictionary *l in [result objectForKey:@"objects"]) {
                NSString *displayValue = [l objectForKey:@"title"];
                [displayValues addObject:displayValue];
                NSString *saveValue = [l objectForKey:@"resource_uri"];
                [saveValues addObject:saveValue];
            }
            
            [self.curOptionController optionsEnumeratedDisplay:displayValues save:saveValues];
        }
    }];
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController *)optionController
{

}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	if (![self validateItem]) return NO;
    
    NSString *list = [self.item customValueForKey:@"list"];
    NSString *notes = [self.item customValueForKey:@"notes"];
    if (notes == nil) notes = @"";
    
    NSDictionary *clip = [NSDictionary dictionaryWithObjectsAndKeys:
                          [self.item.URL absoluteString], @"url",
                          self.item.title, @"title",
                          list, @"list",
                          notes, @"notes",
                          nil];
    
    NSError *error = nil;
    NSData *clipData = [NSJSONSerialization dataWithJSONObject:clip options:NSJSONWritingPrettyPrinted error:&error];
    NSString *clipString = [[NSString alloc] initWithData:clipData encoding:NSUTF8StringEncoding];
    
    [self sendRequest:kNewClipURL params:clipString  method:@"POST" completion:^ (SHKRequest *request) {
        
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
        SHKLog(@"share failed with error: %@", [request description]);
        }
    }];
    
    // Notify delegate
    [self sendDidStart];
    return YES;
}

@end