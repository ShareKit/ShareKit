//
//  SHKVkontakteForm.h
//  forismatic
//
//  Created by MacBook on 06.12.11.
//  Copyright (c) 2011 Alterplay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHKVkontakteForm : UIViewController <UITextViewDelegate>
{
	id delegate;
	UITextView *textView;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) UITextView *textView;

- (void)save;
- (void)keyboardWillShow:(NSNotification *)notification;

@end