//
//  LiveAuthDialog.h
//  Live SDK for iOS
//
//  Copyright 2014 Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
