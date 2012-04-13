//
//  UIAlertView+Dropbox.m
//  Dropbox
//
//  Created by Brian Smith on 4/21/11.
//  Copyright 2011 Dropbox, Inc. All rights reserved.
//

#import "UIAlertView+Dropbox.h"

#import "DBDefines.h"


@implementation UIAlertView (Dropbox)

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message
delegate:(id<UIAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle
otherButtonTitles:(NSString *)otherButtonTitles, ... {

    va_list args;
    va_start(args, otherButtonTitles);
    [[[[UIAlertView alloc]
       initWithTitle:title message:message delegate:delegate cancelButtonTitle:cancelButtonTitle
       otherButtonTitles:otherButtonTitles, args, nil]
      autorelease]
     show];
    va_end(args);
}

@end

DB_FIX_CATEGORY_BUG(UIAlertView_Dropbox)
