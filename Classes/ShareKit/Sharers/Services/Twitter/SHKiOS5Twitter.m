//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOS5Twitter.h"
#import <Twitter/Twitter.h>

@interface SHKiOS5Twitter ()

@end

@implementation SHKiOS5Twitter

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Twitter");
}

+ (NSString *)sharerId
{
	return @"SHKTwitter";
}

- (void)share {
    
    if ([self.item shareType] == SHKShareTypeUserInfo) {
        SHKLog(@"User info not possible to download on iOS5+. You can get Twitter enabled user info from Accounts framework");
        return;
    }
    
    TWTweetComposeViewController *sharerUIController = [[TWTweetComposeViewController alloc] init];
    [sharerUIController addImage:self.item.image];
    [sharerUIController addURL:self.item.URL];
    
    NSString *tweetBody = [NSString stringWithString:(self.item.shareType == SHKShareTypeText ? self.item.text : self.item.title)];
    
    NSString *tagString = [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#" tagSuffix:nil];
    if ([tagString length] > 0) tweetBody = [tweetBody stringByAppendingFormat:@" %@",tagString];
    
    // Trim string to fit 140 character max.
    NSUInteger textLength = [tweetBody length] > 140 ? 140 : [tweetBody length];
    
    while ([sharerUIController setInitialText:[tweetBody substringToIndex:textLength]] == NO && textLength > 0) {
        textLength--;
    }
    
    sharerUIController.completionHandler = ^(SLComposeViewControllerResult result)
    {
        [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
        
        switch (result) {
                
            case TWTweetComposeViewControllerResultDone:
                [self sendDidFinish];
                break;
                
            case TWTweetComposeViewControllerResultCancelled:
                [self sendDidCancel];
                
            default:
                break;
        }
    };
    
    [[SHK currentHelper] showStandaloneViewController:sharerUIController];
    [sharerUIController autorelease];
}

@end
