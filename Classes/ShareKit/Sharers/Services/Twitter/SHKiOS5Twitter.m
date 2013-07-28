//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
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

#import "SHKiOS5Twitter.h"

#import "SharersCommonHeaders.h"

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
}

@end
