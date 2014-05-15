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

/**
* Due to the bug in ios SDK we need to keep reference to ACAccountStore.
*/
@property (nonatomic, strong) ACAccountStore * accountStore;

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
    
    if (self.item.shareType == SHKShareTypeFile || self.item.shareType == SHKShareTypeUserInfo) return NO;
    
    SLComposeViewController *sharerUIController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    
    if (self.item.image) {
        BOOL addedImage = [sharerUIController addImage:self.item.image];
        if (!addedImage) return NO;
    }

    if (self.item.URL) {
        BOOL addedURL = [sharerUIController addURL:self.item.URL];
        if (!addedURL) return NO;
    }
    
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
    
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
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
    
    ACAccountType *sharerAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
    
    [self.accountStore requestAccessToAccountsWithType:sharerAccountType
                                   options:nil
                                completion:^(BOOL granted, NSError *error) {
                                    
                                    [self authDidFinish:granted];
    
                                    if (granted) {
                                        [self tryPendingAction];
                                    } else {
                                        [self iOSAuthorizationFailedWithError:error];                                        
                                        [[self class] logout];
                                    }
                                }];
}

- (void)iOSAuthorizationFailedWithError:(NSError *)error {
    
    if (!error) {
        [self presentRevokedAccessInSettingsAlert];
    } else {
        SHKLog(@"auth failed:%@", [error description]);
        //code 6 means user account not exists in settings.app (at least for Facebook)
        if ([error.domain isEqualToString:@"com.apple.accounts"] && error.code == 6) {
            [self presentNoAvailableAccountAlert];
        } else if ([error.domain isEqualToString:@"com.apple.accounts"] && error.code == 8) {
            SHKLog(@"Missing Facebook app id - set it in your configurator");
        }
        //code 7 user just has not allowed access - no need to show alert.
    }
    [[self class] logout];
}

#pragma mark - Authorization helpers

- (NSArray *)availableAccounts {
    
    ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:[self accountTypeIdentifier]];
    NSArray *result = [self.accountStore accountsWithAccountType:twitterAccountType];
    return result;
}

- (void)presentNoAvailableAccountAlert {
    
    SHKLog(@"User revoked access in settings.app, or in service itself.");
    
    if (self.quiet) return;
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        NSString *alertTitle = SHKLocalizedString(@"No %@ Accounts", [[self class] sharerTitle]);
        NSString *alertMessage = SHKLocalizedString(@"There are no %@ accounts configured. You can add or create a %@ account in Settings.", [[self class] sharerTitle], [[self class] sharerTitle]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMessage
                                                       delegate:nil
                                              cancelButtonTitle:SHKLocalizedString(@"Cancel")
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (void)presentRevokedAccessInSettingsAlert {
    
    if (self.quiet) return;
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        
        NSString *alertTitle = SHKLocalizedString(@"No Access", [[self class] sharerTitle]);
        NSString *alertMessage = SHKLocalizedString(@"Access to %@ is not allowed for this app. You can allow access in Settings.", [[self class] sharerTitle]);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:alertTitle
                                                        message:alertMessage
                                                       delegate:nil
                                              cancelButtonTitle:SHKLocalizedString(@"Cancel")
                                              otherButtonTitles:nil];
        [alert show];
    });
}

#pragma mark - MISC

- (NSString *)joinedTags {
    
    return nil;
}

#pragma mark - ACAccountStore lazy loading

- (ACAccountStore *)accountStore {
    if (!_accountStore) {
        _accountStore = [[ACAccountStore alloc] init];
    }
    return _accountStore;
}


@end
