//
//  UIAlertView+Dropbox.h
//  Dropbox
//
//  Created by Brian Smith on 4/21/11.
//  Copyright 2011 Dropbox, Inc. All rights reserved.
//


@interface UIAlertView (Dropbox)

// Thanks to Marton Fodor for this method
+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message 
delegate:(id<UIAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle
otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

@end
