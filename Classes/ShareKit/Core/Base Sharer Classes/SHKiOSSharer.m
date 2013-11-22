//
//  SHKiOSSharerViewController.m
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOSSharer_Protected.h"
#import "SharersCommonHeaders.h"
#import "UIApplication+iOSVersion.h"
#import <Social/Social.h>

@interface SHKiOSSharer ()

@end

@implementation SHKiOSSharer

#pragma mark - Abstract methods

- (NSString *)accountTypeIdentifier {
    
    NSAssert(NO, @"Abstract method. Must be subclassed!");
    return nil;
}

- (NSString *)serviceTypeIdentifier {
    
    NSAssert(NO, @"Abstract method. Must be subclassed!");
    return nil;
}

#pragma mark - UI

- (void)show {

    if ([SHKCONFIG(useAppleShareUI) boolValue]) {
        
        BOOL nativeUISuccessful = [self shareWithServiceType:[self serviceTypeIdentifier]];
        if (nativeUISuccessful) return; //shared via iOS native UI
    }
    
    [super show];
}

- (BOOL)shareWithServiceType:(NSString *)serviceType {
    
    if (self.item.shareType == SHKShareTypeFile) return NO;
    
    SLComposeViewController *sharerUIController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    
    BOOL addedImage = [sharerUIController addImage:self.item.image];
    if (!addedImage) return NO;
    
    BOOL addedURL = [sharerUIController addURL:self.item.URL];
    if (!addedURL) return NO;
    
    NSString *initialText = (self.item.shareType == SHKShareTypeText ? self.item.text : self.item.title);
    
    NSString *tagString = [self joinedTags];
    if ([tagString length] > 0) initialText = [initialText stringByAppendingFormat:@" %@",tagString];

        
    NSUInteger textLength = [initialText length];
    
    while ([sharerUIController setInitialText:[initialText substringToIndex:textLength]] == NO && textLength > 0) {
        textLength--;
    }
    
    sharerUIController.completionHandler = ^(SLComposeViewControllerResult result)
    {
        
        if ([[UIApplication sharedApplication] isiOS6OrOlder]) {
            [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
        } else {
            [[SHK currentHelper] setCurrentView:nil];
        }
        
        switch (result) {
                
            case SLComposeViewControllerResultDone:
                [self sendDidFinish];
                break;
                
            case SLComposeViewControllerResultCancelled:
                [self sendDidCancel];
                
            default:
                break;
        }
    };
    
    [[SHK currentHelper] showStandaloneViewController:sharerUIController];
    return YES;
}

#pragma mark - Authorization

- (BOOL)isAuthorized {
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
    BOOL result = accountType.accessGranted;
    
    if (!result) [[self class] logout]; //destroy userInfo
    
    return result;
}

- (BOOL)isSharerReady {
    
    if ([self availableAccounts].count > 0) {
        return YES;
    } else {
        [self presentNoAvailableAccountAlert];
        return NO;
    }
}

- (void)authorizationFormShow {
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *sharerAccountType = [store accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
    
    [store requestAccessToAccountsWithType:sharerAccountType
                                   options:nil
                                completion:^(BOOL granted, NSError *error) {
                                    
                                    [self authDidFinish:granted];
    
                                    if (!error) {
                                        [self tryPendingAction];
                                    } else {
                                        SHKLog(@"auth failed:%@", [error description]);
                                        [[self class] logout];
                                    }
                                }];
}

- (void)iOSAuthorizationFailedWithError:(NSError *)error {
    
    if (!error) {
        SHKLog(@"User revoked access in settings.app, or in service itself.");
    } else {
        SHKLog(@"auth failed:%@", [error description]);
        if ([error.domain isEqualToString:@"com.apple.accounts"] && error.code == 6) {
            [self presentNoAvailableAccountAlert];
        }
    }
    [[self class] logout];
}

#pragma mark - Authorization helpers

- (NSArray *)availableAccounts {
    
    ACAccountStore *store = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [store accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
    NSArray *result = [store accountsWithAccountType:twitterAccountType];
    return result;
}

- (void)presentNoAvailableAccountAlert {
    
    NSString *alertTitle = SHKLocalizedString(@"No %@ Accounts", [[self class] sharerTitle]);
    NSString *alertMessage = SHKLocalizedString(@"There are no %@ accounts configured. You can add or create a %@ account in Settings.", [[self class] sharerTitle], [[self class] sharerTitle]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                    message:alertMessage
                                                   delegate:nil
                                          cancelButtonTitle:SHKLocalizedString(@"Cancel")
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - MISC

- (NSString *)joinedTags {
    
    return nil;
}

@end
