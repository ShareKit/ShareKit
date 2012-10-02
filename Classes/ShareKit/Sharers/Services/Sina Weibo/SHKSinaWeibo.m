//  Created by James Chen on 10/2/2012.

#import <Social/Social.h>
#import "SHKSinaWeibo.h"

@interface SHKSinaWeibo ()

@property (retain) UIViewController *currentTopViewController;

- (void)callUI:(NSNotification *)notif;
- (void)presentUI;

@end

@implementation SHKSinaWeibo

@synthesize currentTopViewController;

- (void)dealloc {
    [currentTopViewController release];
    [super dealloc];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Sina Weibo";
}

+ (NSString *)sharerId
{
	return @"SHKSinaWeibo";
}

+ (BOOL)canShareURL
{
    return YES;
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)canShareText
{
    return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the action.  (For example if it only works with specific hardware)
+ (BOOL)canShare
{
	return YES;
}

#pragma mark -
#pragma mark Implementation

- (void)share {
    if ([[SHK currentHelper] currentView]) { //user is sharing from SHKShareMenu    
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(callUI:) 
                                                     name:SHKHideCurrentViewFinishedNotification                                       
                                                   object:nil];
        [self retain];
        
    } else {  
        [self presentUI];   
    }
}

- (void)callUI:(NSNotification *)notif {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SHKHideCurrentViewFinishedNotification object:nil];
    [self presentUI];
    [self release];
}

- (void)presentUI {
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
        return;
    }

    SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeSinaWeibo];
    [composeViewController addImage:self.item.image];
    [composeViewController addURL:self.item.URL];

    NSString *text = [NSString stringWithString:(self.item.shareType == SHKShareTypeText ? item.text : item.title)];
    NSString *tagString = [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#"];
    if ([tagString length] > 0) {
        text = [text stringByAppendingFormat:@" %@",tagString];
    }

    NSUInteger textLength = MIN([text length], 280);
    while ([composeViewController setInitialText:[text substringToIndex:textLength]] == NO && textLength > 0) {
        textLength--;
    }

    composeViewController.completionHandler = ^(SLComposeViewControllerResult result) {
         [self.currentTopViewController dismissViewControllerAnimated:YES completion:^{                                                                           
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SHKHideCurrentViewFinishedNotification object:nil];
            }];
        }];

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

    self.currentTopViewController = [[SHK currentHelper] rootViewForCustomUIDisplay];
    [self.currentTopViewController presentViewController:composeViewController animated:YES completion:nil];
}

@end
