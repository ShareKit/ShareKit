//
//  SHKFacebookForm.h
//  ShareKit
//

#import <UIKit/UIKit.h>

@protocol SHKFormControllerLargeTextFieldDelegate;

@interface SHKFormControllerLargeTextField : UIViewController <UITextViewDelegate>

@property (nonatomic, readonly, weak) id <SHKFormControllerLargeTextFieldDelegate> delegate;
@property (nonatomic, strong) UITextView *textView;

// these properties are used for counter text display only. 
// Counter shows, only if they are set by your sharer.
@property NSUInteger maxTextLength;
@property (nonatomic, strong) UIImage *image;//ready for showing up image, like ios5 twitter
@property NSUInteger imageTextLength; //set only if image subtracts from text length (e.g. Twitter)
@property BOOL hasLink; //only if the link is not part of the text in a text view
@property BOOL allowSendingEmptyMessage;
@property (nonatomic, strong) NSString *text;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id <SHKFormControllerLargeTextFieldDelegate>)aDelegate;

@end

@protocol SHKFormControllerLargeTextFieldDelegate <NSObject> 
@required
- (void)sendForm:(SHKFormControllerLargeTextField *)form;
+ (NSString *)sharerTitle;
- (void)sendDidCancel;

@end
