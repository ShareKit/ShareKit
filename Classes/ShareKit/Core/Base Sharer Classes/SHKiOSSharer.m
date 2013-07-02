//
//  SHKiOSSharerViewController.m
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOSSharer_Protected.h"
#import "SharersCommonHeaders.h"
#import <Social/Social.h>

@interface SHKiOSSharer ()

@end

@implementation SHKiOSSharer

- (void)shareWithServiceType:(NSString *)serviceType {
    
    if ([self.item shareType] == SHKShareTypeUserInfo) {
        SHKLog(@"User info not possible to download on iOS sharing. You can get service enabled user info from Accounts framework");
        return;
    }
    
    SLComposeViewController *sharerUIController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    
    [sharerUIController addImage:self.item.image];
    [sharerUIController addURL:self.item.URL];
    
    NSString *initialText = (self.item.shareType == SHKShareTypeText ? self.item.text : self.item.title);
    
    NSString *tagString = [self joinedTags];
    if ([tagString length] > 0) initialText = [initialText stringByAppendingFormat:@" %@",tagString];

    // Trim string to fit limit, if any.    
    if (self.maxTextLength != NSNotFound) {
        
        NSUInteger textLength = [initialText length] > self.maxTextLength ? self.maxTextLength : [initialText length];
        while ([sharerUIController setInitialText:[initialText substringToIndex:textLength]] == NO && textLength > 0) {
            textLength--;
        }
        
    } else {
        
        [sharerUIController setInitialText:initialText];
    }
    
    sharerUIController.completionHandler = ^(SLComposeViewControllerResult result)
    {
        [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
        
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
}

- (NSString *)joinedTags {
    
    return nil;
}

- (NSUInteger)maxTextLength {
    
    return NSNotFound;
}

@end
