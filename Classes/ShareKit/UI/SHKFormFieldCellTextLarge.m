//
//  SHKFormFieldCellTextLarge.m
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
//
//

#import "SHKFormFieldCellTextLarge.h"
#import "SHKFormFieldCell_PrivateProperties.h"
#import "SHKFormFieldLargeTextSettings.h"
#import "SSTextView.h"

#define SHK_FORM_CELL_PAD_TOP 7
#define SHK_FORM_CELL_PAD_BOTTOM 28
#define SHK_FORM_CELL_PAD_PHOTO_WIDTH 44

#define SHK_FORM_CELL_COUNTER_WIDTH 40
#define SHK_FORM_CELL_COUNTER_HEIGHT 20

@interface SHKFormFieldCellTextLarge ()

@property (weak, nonatomic) SSTextView *textView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) UILabel *counter;

@property (strong, nonatomic) SHKFormFieldLargeTextSettings *settings;

@end

@implementation SHKFormFieldCellTextLarge

- (void)setupLayout {
    
    SSTextView *textView = [[SSTextView alloc] initWithFrame:[self frameForTextview]];
    textView.delegate = self;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.contentInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    textView.font = [UIFont systemFontOfSize:17];
    textView.textColor = [UIColor darkGrayColor];
    textView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:textView];
    self.textView = textView;
    
    CGRect counterRect = CGRectMake(self.contentView.frame.size.width - SHK_FORM_CELL_COUNTER_WIDTH - SHK_FORM_CELL_PAD_RIGHT,
                                    self.contentView.frame.size.height - SHK_FORM_CELL_COUNTER_HEIGHT - SHK_FORM_CELL_PAD_TOP,
                                    SHK_FORM_CELL_COUNTER_WIDTH, SHK_FORM_CELL_COUNTER_HEIGHT);
        
    UILabel *counter = [[UILabel alloc] initWithFrame:counterRect];
    counter.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    counter.textAlignment = UITextAlignmentRight;
    counter.font = [UIFont systemFontOfSize:17];
    counter.textColor = [UIColor darkGrayColor];
    counter.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:counter];
    self.counter = counter;
    
    [super setupLayout];
}

- (CGRect)frameForTextview {
    
    CGFloat photoWidth = self.settings.image ? SHK_FORM_CELL_PAD_PHOTO_WIDTH : 0;
    CGRect result = CGRectMake(SHK_FORM_CELL_PAD_RIGHT/4,
                              SHK_FORM_CELL_PAD_TOP,
                              self.contentView.bounds.size.width - SHK_FORM_CELL_PAD_RIGHT/4 - SHK_FORM_CELL_PAD_LEFT/4 - photoWidth,
                              self.contentView.bounds.size.height - SHK_FORM_CELL_PAD_TOP - SHK_FORM_CELL_PAD_BOTTOM);
    return result;
}

- (void)setupWithSettings:(SHKFormFieldSettings *)settings {
    
    [super setupWithSettings:settings];
    
    self.textView.text = settings.displayValue;
    self.textView.placeholder = settings.label;
    [self updateCounter];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selected) {
        [self.textView becomeFirstResponder];
    } else {
        [self.textView resignFirstResponder];
    }
}

#pragma mark counter updates

- (void)updateCounter
{	
	self.settings.displayValue = self.textView.text;
    [self.delegate valueChanged];
    
    if (!self.settings.maxTextLength) return;
		   
    NSUInteger imageTextLength = (self.settings.image && self.settings.imageTextLength) ? self.settings.imageTextLength : 0;

    NSInteger countNumber = self.settings.maxTextLength - [self.textView.text length] - imageTextLength;
    NSString *count = [NSString stringWithFormat:@"%i", countNumber];
    self.counter.text = count;
 	
	if (countNumber >= 0) {
		self.counter.textColor = [UIColor darkGrayColor];
	} else {
		self.counter.textColor = [UIColor redColor];
	}
}

#pragma mark UITextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

@end
