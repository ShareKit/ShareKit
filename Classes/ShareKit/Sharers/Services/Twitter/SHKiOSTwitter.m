//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 17.11.2011.
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

#import "SHKiOSTwitter.h"
#import "SHKiOSSharer_Protected.h"

#import "SharersCommonHeaders.h"
#import "SHKTwitterCommon.h"
#import "SHKXMLResponseParser.h"
#import "SHKRequest.h"
#import "SHKSession.h"

#import "NSMutableURLRequest+Parameters.h"

typedef void (^SHKRequestHandlerBlock)(NSData *responseData, NSURLResponse *urlResponse, NSError *error);

@implementation SHKiOSTwitter

#pragma mark - SHKSharer config

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Twitter"); }

+ (BOOL)canGetUserInfo { return YES; }
+ (BOOL)canShareURL { return YES; }
+ (BOOL)canShareText { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file {
    
    BOOL result = [SHKTwitterCommon canShareFile:file];
    return result;
}

+ (BOOL)canShare {
    
    return [SHKTwitterCommon socialFrameworkAvailable];
}

#pragma mark - SHKiOSSharer config

- (NSString *)accountTypeIdentifier { return ACAccountTypeIdentifierTwitter; }
- (NSString *)serviceTypeIdentifier { return SLServiceTypeTwitter; }

- (NSString *)joinedTags {
    return [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#" tagSuffix:nil];
}

#pragma mark - Authorization

- (BOOL)isAuthorized {
    
    BOOL result = [super isAuthorized];
    if (result) {
        [self downloadAPIConfiguration]; //fetch fresh file size limits
    }
    return result;
}
+ (NSString *)username {
    
    NSArray *usersInfos = [[NSUserDefaults standardUserDefaults] arrayForKey:kSHKiOSTwitterUserInfo];
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:3];
    
    for (NSDictionary *userInfo in usersInfos) {
        NSString *name = userInfo[SHKTwitterAPIUserInfoNameKey];
        [names addObject:name];
    }
    
    NSString *result = [names componentsJoinedByString:@", "];
    return result;
}

+ (void)logout {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKiOSTwitterUserInfo];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKTwitterAPIConfigurationDataKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKTwitterAPIConfigurationSaveDateKey];
}

#pragma mark - UI

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {

    if (self.item.shareType == SHKShareTypeUserInfo) return nil;
    
    [SHKTwitterCommon prepareItem:self.item joinedTags:[self joinedTags]];
    
    SHKFormFieldLargeTextSettings *largeTextSettings = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Tweet")
                                                                                        key:@"status"
                                                                                      start:[self.item customValueForKey:@"status"]
                                                                                       item:self.item];
    largeTextSettings.maxTextLength = [SHKTwitterCommon maxTextLengthForItem:self.item];
    largeTextSettings.select = YES;
    largeTextSettings.validationBlock = ^(SHKFormFieldLargeTextSettings *formFieldSettings) {
        
        BOOL emptyCriterium =  [formFieldSettings.valueToSave length] > 0;
        BOOL maxTextLenCriterium = [formFieldSettings.valueToSave length] <= formFieldSettings.maxTextLength;
        
        if (emptyCriterium && maxTextLenCriterium) {
            return YES;
        } else {
            return NO;
        }
    };
    
    NSMutableArray *result = [NSMutableArray arrayWithObject:largeTextSettings];
    
    NSArray *availableAccounts = [self availableAccounts];
    if ([availableAccounts count] > 1) {
        
        NSMutableArray *usernames = [NSMutableArray arrayWithCapacity:0];
        for (ACAccount *account in availableAccounts) {
            [usernames addObject:account.username];
        }
        SHKFormFieldOptionPickerSettings *accountField = [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Account")
                                                                                             key:@"account"
                                                                                           start:[(ACAccount *)availableAccounts[0] username]
                                                                                     pickerTitle:SHKLocalizedString(@"Account")
                                                                                 selectedIndexes:[[NSMutableIndexSet alloc] initWithIndex:0]
                                                                                   displayValues:usernames
                                                                                      saveValues:nil
                                                                                   allowMultiple:NO
                                                                                    fetchFromWeb:NO
                                                                                        provider:nil];
        [result addObject:accountField];
    }
    
    return result;
}

#pragma mark - Share

- (BOOL)send {
    
    if (![self validateItem]) return NO;
    
    //Needed for silent share. Normally status is aggregated just before presenting the UI
    if (![self.item customValueForKey:@"status"]) {
        [SHKTwitterCommon prepareItem:self.item joinedTags:[self tagStringJoinedBy:@" "
                                                                 allowedCharacters:[NSCharacterSet alphanumericCharacterSet]
                                                                         tagPrefix:@"#" tagSuffix:nil]];
    }
    
    if (self.item.image || self.item.file) {

        if (self.item.image && !self.item.file) {
            [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:1];
        }
        
        if ([SHKTwitterCommon canTwitterAcceptFile:self.item.file]) {
            [self sendStatusViaTwitter:self.item.file];
        } else {
            [self sendDataViaYFrog:self.item.file.data mimeType:self.item.file.mimeType filename:self.item.file.filename];
        }
        
    } else if (self.item.shareType == SHKShareTypeUserInfo) {
        self.quiet = YES;
        [self fetchUserInfo];
    } else {
        [self sendStatusViaTwitter:nil];
    }

    [self sendDidStart];
    return YES;
}

- (void)sendStatusViaTwitter:(SHKFile *)file {
    
    NSURL *url;
    if (file) {
        url = [NSURL URLWithString:SHKTwitterAPIUpdateWithMediaURL];
    } else {
        url = [NSURL URLWithString:SHKTwitterAPIUpdateURL];
    }
    
    NSDictionary *params = @{@"status":[self.item customValueForKey:@"status"]};
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:params];
    
    if (file) [request addMultipartData:file.data withName:@"media" type:file.mimeType filename:file.filename];
    request.account = [self selectedAccount];
    
    BOOL canUseNSURLSession = NSClassFromString(@"NSURLSession") != nil;
    if (file && canUseNSURLSession) {
        NSURLRequest *preparedRequest = [request preparedURLRequest];
        self.networkSession = [SHKSession startSessionWithRequest:preparedRequest delegate:self completion:[self twitterDataStatusRequestHandler]];
    } else {
        [request performRequestWithHandler:[self twitterDataStatusRequestHandler]];
    }
}

- (SHKRequestHandlerBlock)twitterDataStatusRequestHandler {
    
    SHKRequestHandlerBlock result = ^(NSData *responseData, NSURLResponse *urlResponse, NSError *error) {
        
        if (error) {
            
            if (error.code == -999) {
                [self sendDidCancel];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self sendDidFailWithError:error];
                });
            }
            
        } else {
            
            BOOL requestDidSucceed = [(NSHTTPURLResponse *)urlResponse statusCode] < 400;
            if (requestDidSucceed) {
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self sendDidFinish];
                });
                
                
            } else {
                
                if (SHKDebugShowLogs) SHKLog(@"Twitter Send Status Error: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                
                NSMutableDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
                NSDictionary *twitterError = parsedResponse[@"errors"][0];
                NSError *ourError = [NSError errorWithDomain:@"Twitter" code:2 userInfo:[NSDictionary dictionaryWithObject:twitterError[@"message"] forKey:NSLocalizedDescriptionKey]];
                
                dispatch_async(dispatch_get_main_queue(), ^ {
                    [self sendDidFailWithError:ourError];
                });
            }
        }
    };
    return result;
}

- (void)sendDataViaYFrog:(NSData *)data mimeType:(NSString *)mimeType filename:(NSString *)filename {
    
    BOOL canUseNSURLSession = NSClassFromString(@"NSURLSession") != nil;
    if (canUseNSURLSession) {
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"https://yfrog.com/api/xauth_upload"]];
        [request setHTTPMethod:@"POST"];
        request.allHTTPHeaderFields = @{@"X-Auth-Service-Provider": @"https://api.twitter.com/1.1/account/verify_credentials.json",
                                        @"X-Verify-Credentials-Authorization": [self authorizationYFrogHeader]};
        
        //encountered 411 length required, thus not attachFile:withParameterName
        [request attachFileWithParameterName:@"media" filename:filename contentType:mimeType data:data];
        self.networkSession = [SHKSession startSessionWithRequest:request delegate:self completion:[self yFrogRequestCompletion]];
        
    } else {
        
        SLRequest *yFrogUploadRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                           requestMethod:SLRequestMethodPOST
                                                                     URL:[[NSURL alloc] initWithString:@"https://yfrog.com/api/xauth_upload"]
                                                              parameters:@{@"X-Auth-Service-Provider": @"https://api.twitter.com/1.1/account/verify_credentials.json",
                                                                           @"X-Verify-Credentials-Authorization": [self authorizationYFrogHeader]}];
        [yFrogUploadRequest addMultipartData:data withName:@"media" type:mimeType filename:filename];
        [yFrogUploadRequest performRequestWithHandler:[self yFrogRequestCompletion]];
    }
}

- (SHKRequestHandlerBlock)yFrogRequestCompletion {
    
    SHKRequestHandlerBlock result = ^(NSData *responseData, NSURLResponse *urlResponse, NSError *error) {
        
        if (!error) {
            
            if ([(NSHTTPURLResponse *)urlResponse statusCode] < 400) {
                
                NSString *mediaURL = [SHKXMLResponseParser getValueForElement:@"mediaurl" fromXMLData:responseData];
                if (mediaURL) {
                    
                    [self.item setCustomValue:[NSString stringWithFormat:@"%@ %@", [self.item customValueForKey:@"status"], mediaURL] forKey:@"status"];
                    [self sendStatusViaTwitter:nil];
                    
                } else {
                    
                    [SHKTwitterCommon handleUnsuccessfulTicket:responseData forSharer:self];
                }
                
            } else {
                
                [self sendShowSimpleErrorAlert];
            }
            
        } else {
            
            if (error.code == -999) {
                [self sendDidCancel];
            } else {
                [self sendDidFailWithError:error];
            }
        }
    };
    return result;
}

- (void)fetchUserInfo {
    
    //clear user info, as user might have changed accounts in settings.app
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKiOSTwitterUserInfo];
    
    for (ACAccount *account in [self availableAccounts]) {
        
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                requestMethod:SLRequestMethodGET
                                                          URL:[NSURL URLWithString:SHKTwitterAPIUserInfoURL]
                                                   parameters:nil];
        request.account = account;
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {

            if (!error && urlResponse.statusCode < 400) {
                [SHKTwitterCommon saveData:responseData defaultsKey:kSHKiOSTwitterUserInfo];
                SHKLog(@"response:%@", [urlResponse description]);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self sendDidFinish];
                });
            }
        }];
    }
}

- (void)downloadAPIConfiguration {
    
    NSDate *lastFetchDate = [[NSUserDefaults standardUserDefaults] objectForKey:SHKTwitterAPIConfigurationSaveDateKey];
    BOOL isConfigOld = [[NSDate date] compare:[lastFetchDate dateByAddingTimeInterval:24*60*60]] == NSOrderedDescending;
    if (isConfigOld || !lastFetchDate) {
        
        ACAccount *anyTwitterAccount = [[self availableAccounts] lastObject];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                requestMethod:SLRequestMethodGET
                                                          URL:[NSURL URLWithString:SHKTwitterAPIConfigurationURL]
                                                   parameters:nil];
        request.account = anyTwitterAccount;
        [request performRequestWithHandler:^ (NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            
            if (!error && urlResponse.statusCode < 400) {
                [SHKTwitterCommon saveData:responseData defaultsKey:SHKTwitterAPIConfigurationDataKey];
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SHKTwitterAPIConfigurationSaveDateKey];
            }
        }];
    }
}
                              
#pragma mark - helpers

- (ACAccount *)selectedAccount {
    
    NSArray *availableAccounts = [self availableAccounts];
    NSString *selectedUsername = [self.item customValueForKey:@"account"];
    ACAccount *result;
    
    if (selectedUsername) {
        
        NSUInteger indexOfSelectedAccount = [availableAccounts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return ([[(ACAccount *)obj username] isEqualToString:selectedUsername]);
        }];
        result = availableAccounts[indexOfSelectedAccount];
        
    } else {
        
        //during silent share we do not know, what account should be used, thus we choose the last one. Might be done better in the future, if there is demand
        result = [availableAccounts lastObject];
    }
    return result;
}

- (NSString *)authorizationYFrogHeader {
    
    SLRequest *twitterRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                   requestMethod:SLRequestMethodPOST
                                                             URL:[[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/account/verify_credentials.xml"]
                                                      parameters:nil];
    twitterRequest.account = [self selectedAccount];
    NSURLRequest *preparedRequest = [twitterRequest preparedURLRequest];
    NSDictionary *headerDict = [preparedRequest allHTTPHeaderFields];
    NSString *result = [headerDict valueForKey:@"Authorization"];
    return result;
}

@end
