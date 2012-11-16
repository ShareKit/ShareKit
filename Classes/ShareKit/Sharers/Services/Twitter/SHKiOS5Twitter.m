//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 17.11.2011.
//  Copyright (c) 2011 Cocoa Miners. All rights reserved.
//

#import "SHKiOS5Twitter.h"
#import "SHK.h"
#import <Twitter/Twitter.h>

@interface SHKiOS5Twitter ()

@end

@implementation SHKiOS5Twitter

- (void)dealloc {

    [super dealloc];
}

+ (NSString *)sharerTitle
{
	return @"Twitter";
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
    
    TWTweetComposeViewController *iOS5twitter = [[TWTweetComposeViewController alloc] init];
    
    [iOS5twitter addImage:self.item.image];
    [iOS5twitter addURL:self.item.URL];
    
    NSString *tweetBody = [NSString stringWithString:(self.item.shareType == SHKShareTypeText ? item.text : item.title)];
    
    NSString *tagString = [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#"];
    if ([tagString length] > 0) tweetBody = [tweetBody stringByAppendingFormat:@" %@",tagString];
    
    // Trim string to fit 140 character max.
    NSUInteger textLength = [tweetBody length] > 140 ? 140 : [tweetBody length];
    
    while ([iOS5twitter setInitialText:[tweetBody substringToIndex:textLength]] == NO && textLength > 0) {
        textLength--;
    }
    
    iOS5twitter.completionHandler = ^(TWTweetComposeViewControllerResult result)
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
    
    [[SHK currentHelper] showStandaloneViewController:iOS5twitter];
    [iOS5twitter release];
}

@end
