//
//  SHKiOSFacebook.m
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOSFacebook.h"
#import "SHKiOSSharer_Protected.h"

#import "SharersCommonHeaders.h"
#import "SHKFacebookCommon.h"
#import "SHKSession.h"

#import "NSMutableDictionary+NSNullsToEmptyStrings.h"
#import "NSMutableURLRequest+Parameters.h"

#import <Accounts/Accounts.h>

typedef void (^SHKRequestHandler)(NSData *responseData, NSURLResponse *urlResponse, NSError *error);

@implementation SHKiOSFacebook

#pragma mark - SHKSharer config

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"Facebook"); }

+ (BOOL)canGetUserInfo { return YES; }
+ (BOOL)canShareURL { return YES; }
+ (BOOL)canShareText { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file {
    
    BOOL result = [SHKFacebookCommon canFacebookAcceptFile:file];
    return result;
}

+ (BOOL)canShare {
    
    return [SHKFacebookCommon socialFrameworkAvailable];
}

#pragma mark - SHKiOSSharer config

- (NSString *)accountTypeIdentifier { return ACAccountTypeIdentifierFacebook; }
- (NSString *)serviceTypeIdentifier { return SLServiceTypeFacebook; }

#pragma mark - Authorization

- (void)authorizationFormShow {
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *sharerAccountType = [store accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
    
    if (![sharerAccountType.identifier isEqualToString:ACAccountTypeIdentifierFacebook]) {
        NSLog(@"Wrong ACAccount type, is nil but should be Facebook type. If you can repeat this situation, please open an issue in ShareKit's Github");
        return;
    }
    NSDictionary *writePermissions = @{ACFacebookAppIdKey: SHKCONFIG(facebookAppId),
                              ACFacebookPermissionsKey: SHKCONFIG(facebookWritePermissions),
                              ACFacebookAudienceKey: ACFacebookAudienceEveryone};
    NSDictionary *readPermissions = @{ACFacebookAppIdKey: SHKCONFIG(facebookAppId),
                              ACFacebookPermissionsKey: @[@"email"],
                              ACFacebookAudienceKey: ACFacebookAudienceEveryone};
    
    switch (self.pendingAction) {
            
        case SHKPendingRefreshToken:
        {
            [store renewCredentialsForAccount:[self availableAccounts][0]
                                   completion:^ (ACAccountCredentialRenewResult renewResult, NSError *error) {
                                       
                                       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                           
                                           if (renewResult == ACAccountCredentialRenewResultRenewed) {
                                               [self tryPendingAction];
                                           } else if (renewResult == ACAccountCredentialRenewResultRejected) {
                                               [self shouldReloginWithPendingAction:SHKPendingSend]; //reauthorize after user rejected on service
                                           } else {
                                               [self iOSAuthorizationFailedWithError:error];
                                           }
                                       }];
                                   }];
            break;
        }
        default:
        {
            [store requestAccessToAccountsWithType:sharerAccountType
                                           options:readPermissions
                                        completion:^(BOOL readGranted, NSError *error) {
                                            
                                                if (readGranted) {
                                                    
                                                    [store requestAccessToAccountsWithType:sharerAccountType
                                                                                   options:writePermissions
                                                                                completion:^(BOOL writeGranted, NSError *error) {
                                                                                    
                                                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                                        
                                                                                        [self authDidFinish:writeGranted];
                                                                                        
                                                                                        if (writeGranted) {
                                                                                            [self tryPendingAction];
                                                                                        } else {
                                                                                            [self iOSAuthorizationFailedWithError:error];
                                                                                        }
                                                                                    }];
                                                                                }];
                                                } else {
                                                    
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                        [self iOSAuthorizationFailedWithError:error];
                                                        [self authDidFinish:NO];
                                                    }];
                                                }
                                        }];
            break;
        }
    }
}

+ (NSString *)username {
    
   return [SHKFacebookCommon username];
}

+ (void)logout {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFacebookUserInfo];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFacebookVideoUploadLimits];
}

#pragma mark - ShareKit UI

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    NSArray *result = [SHKFacebookCommon shareFormFieldsForItem:self.item];
    return result;
}

#pragma mark - Sharing

- (BOOL)send {
    
    if (![self validateItem]) return NO;
    
    switch (self.item.shareType) {
        case SHKShareTypeUserInfo:
            [self fetchUserInfo];
            break;
        case SHKShareTypeText:
        case SHKShareTypeURL:
            [self sendFeed];
            break;
        case SHKShareTypeImage:
            [self sendPhoto];
            break;
        case SHKShareTypeFile:
            [self sendVideo];
            break;
        default:
            break;
    }
    [self sendDidStart];
    
    return YES;
}

- (void)sendFeed {
    
    NSMutableDictionary *params = [SHKFacebookCommon composeParamsForItem:self.item];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodPOST
                                                      URL:[NSURL URLWithString:kSHKFacebookAPIFeedURL]
                                               parameters:params];
    request.account = [self availableAccounts][0];
    [request performRequestWithHandler:[self requestHandler]];
}

- (void)sendPhoto {
    
    NSMutableDictionary *params = [SHKFacebookCommon composeParamsForItem:self.item];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodPOST
                                                      URL:[NSURL URLWithString:kSHKFacebookAPIPhotosURL]
                                               parameters:params];
    CGFloat compression = 1;
	NSData *imageData = UIImageJPEGRepresentation(self.item.image, compression);
    [request addMultipartData:imageData withName:@"source" type:@"image/jpeg" filename:@"image"];
    request.account = [self availableAccounts][0];
    [request performRequestWithHandler:[self requestHandler]];
}

- (void)sendVideo {
    
    NSMutableDictionary *params = [SHKFacebookCommon composeParamsForItem:self.item];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodPOST
                                                      URL:[NSURL URLWithString:kSHKFacebookAPIVideosURL]
                                               parameters:params];
    request.account = [self availableAccounts][0];
    
    BOOL canUseNSURLSession = NSClassFromString(@"NSURLSession") != nil;
    if (canUseNSURLSession) {
        NSURLRequest *preparedRequest = [request preparedURLRequest];
        [(NSMutableURLRequest *)preparedRequest attachFile:self.item.file withParameterName:@"source"];
        self.networkSession = [SHKSession startSessionWithRequest:preparedRequest delegate:self completion:[self requestHandler]];
    } else {
        [request addMultipartData:self.item.file.data withName:@"source" type:self.item.file.mimeType filename:self.item.file.filename];
        [request performRequestWithHandler:[self requestHandler]];
    }
    
    //update video limits
    [[self class] getUserInfo];
}

- (void)fetchUserInfo {
    
    self.quiet = YES;
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                            requestMethod:SLRequestMethodGET
                                                      URL:[NSURL URLWithString:kSHKFacebookAPIUserInfoURL]
                                               parameters:nil];
    request.account = [self availableAccounts][0];
    [request performRequestWithHandler:[self requestHandler]];
    
    SLRequest *videoLimitsRequest = [SLRequest requestForServiceType:SLServiceTypeFacebook
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:[NSURL URLWithString:kSHKFacebookAPIUserInfoURL]
                                                          parameters:@{@"fields": @"video_upload_limits"}];
    videoLimitsRequest.account = [self availableAccounts][0];
    [videoLimitsRequest performRequestWithHandler:[self requestHandler]];
}

- (SHKRequestHandler)requestHandler {
    
    SHKRequestHandler result = ^(NSData *responseData, NSURLResponse *urlResponse, NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            if (!error) {
                
                NSError *parseError;
                NSMutableDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&parseError];
                
                BOOL requestSucceeded = [(NSHTTPURLResponse *)urlResponse statusCode] < 400;
                if (requestSucceeded) {
                    
                    //if this is userinfo, save it
                    if (!parseError && parsedResponse[@"name"]) {
                        
                        [parsedResponse convertNSNullsToEmptyStrings];
                        [[NSUserDefaults standardUserDefaults] setObject:parsedResponse forKey:kSHKFacebookUserInfo];
                        SHKLog(@"saved Facebook UserInfo");
                        
                    } else if (!parseError && parsedResponse[@"video_upload_limits"]) {
                        
                        [parsedResponse convertNSNullsToEmptyStrings];
                        [[NSUserDefaults standardUserDefaults] setObject:parsedResponse forKey:kSHKFacebookVideoUploadLimits];
                        SHKLog(@"saved Facebook Video limits");
                    }
                    
                    [self sendDidFinish];
                    
                } else {
                    
                    //list of error codes https://developers.facebook.com/docs/reference/api/errors/
                    NSUInteger errorSubCode = [parsedResponse[@"error"][@"error_subcode"] integerValue];
                    NSUInteger errorCode = [parsedResponse[@"error"][@"code"] integerValue];
                    
                    //even for 458 (user removed app on Facebook) we should refresh token - this way iOS settings app removes access too. Then we can reauthorize again, if user shares.
                    if (errorSubCode == 458 || errorSubCode == 463 || errorSubCode == 467 || errorCode == 2500 || 200 >= errorCode || errorCode <= 299 || errorCode == 102) {
                        [self shouldReloginWithPendingAction:SHKPendingRefreshToken];
                    } else {
                        [self sendShowSimpleErrorAlert];
                    }
                    SHKLog(@"error: %@", [parsedResponse description]);
                }
                
            } else {
                [self sendDidFailWithError:error];
                SHKLog(@"error:%@", [error description]);
            }
        }];
    };
    return result;
}

@end