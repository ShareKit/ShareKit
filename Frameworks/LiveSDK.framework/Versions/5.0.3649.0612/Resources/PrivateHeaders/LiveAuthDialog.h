//
//  LiveAuthDialog.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveAuthDialogDelegate.h"

@interface LiveAuthDialog : UIViewController<UIWebViewDelegate>
{
@private
    NSURL *_startUrl;
    NSString * _endUrl;
}

- (id)initWithNibName:(NSString *)nibNameOrNil 
               bundle:(NSBundle *)nibBundleOrNil
             startUrl:(NSURL *)startUrl 
               endUrl:(NSString *)endUrl
             delegate:(id<LiveAuthDialogDelegate>)delegate;

@property (assign, nonatomic) id<LiveAuthDialogDelegate> delegate;
@property (retain, nonatomic) IBOutlet UIWebView *webView;
@property (readonly, nonatomic) BOOL canDismiss;

@end
