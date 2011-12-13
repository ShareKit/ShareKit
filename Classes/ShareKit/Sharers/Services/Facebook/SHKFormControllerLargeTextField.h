//
//  SHKFacebookForm.h
//  ShareKit
//

#import <UIKit/UIKit.h>

@protocol SHKFormControllerLargeTextFieldDelegate;

@interface SHKFormControllerLargeTextField : UIViewController <UITextViewDelegate>

@property (nonatomic, readonly, assign) id <SHKFormControllerLargeTextFieldDelegate> delegate;
@property (nonatomic, retain) UITextView *textView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id <SHKFormControllerLargeTextFieldDelegate>)aDelegate;

//internal methods, only here to silence compiler warning when overriden by subclass (SHKTwitterForm).
- (void)save;
- (void)keyboardWillShow:(NSNotification *)notification;

@end

@protocol SHKFormControllerLargeTextFieldDelegate <NSObject> 

- (void)sendForm:(SHKFormControllerLargeTextField *)form;
+ (NSString *)sharerTitle;
- (void)sendDidCancel;

@end
