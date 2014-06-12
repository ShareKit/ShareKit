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
#import "SAMTextView.h"

#import "UIImage+OurBundle.h"
#import "UIApplication+iOSVersion.h"

#define SHK_FORM_TEXT_PAD_TOP 7
#define SHK_FORM_TEXT_PAD_BOTTOM 28

#define SHK_FORM_COUNTER_WIDTH 40
#define SHK_FORM_COUNTER_HEIGHT 20

#define SHK_FORM_PHOTO_PAD_RIGHT 5
#define SHK_FORM_PHOTO_PAD_TOP 1

#define SHK_FORM_EXTENSION_PAD 15

@interface SHKFormFieldCellTextLarge ()

@property (weak, nonatomic) SAMTextView *textView;
@property (weak, nonatomic) UILabel *counter;
@property (weak, nonatomic) UIImageView *clippedImageView;
@property (weak, nonatomic) UIImageView *clipImageView;
@property (weak, nonatomic) UILabel *fileExtension;

@property (strong, nonatomic) SHKFormFieldLargeTextSettings *settings;

@end

@implementation SHKFormFieldCellTextLarge

- (void)setupLayout {
    
    SAMTextView *textView = [[SAMTextView alloc] initWithFrame:[self frameForTextview]];
    textView.delegate = self;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.contentInset = UIEdgeInsetsMake(-8, 0, 0, 0);
    textView.font = [UIFont systemFontOfSize:17];
    textView.textColor = [UIColor darkGrayColor];
    textView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:textView];
    self.textView = textView;
    
    CGRect counterRect = CGRectMake(self.contentView.frame.size.width - SHK_FORM_COUNTER_WIDTH - SHK_FORM_CELL_PAD_RIGHT,
                                    self.contentView.frame.size.height - SHK_FORM_COUNTER_HEIGHT - SHK_FORM_TEXT_PAD_TOP,
                                    SHK_FORM_COUNTER_WIDTH, SHK_FORM_COUNTER_HEIGHT);
        
    UILabel *counter = [[UILabel alloc] initWithFrame:counterRect];
    counter.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    counter.textAlignment = NSTextAlignmentRight;
    counter.font = [UIFont systemFontOfSize:17];
    counter.textColor = [UIColor darkGrayColor];
    counter.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:counter];
    self.counter = counter;
    
    UIImage *image = [UIImage imageNamedFromOurBundle:@"DETweetURLAttachment.png"]; //this image is used just for initial layout, will be replaced during setupWithSettings:
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    CGPoint imageViewCenter = CGPointMake(self.contentView.bounds.size.width - imageView.frame.size.width/2 - SHK_FORM_PHOTO_PAD_RIGHT, self.contentView.bounds.size.height - imageView.frame.size.height/2 - SHK_FORM_TEXT_PAD_TOP - SHK_FORM_TEXT_PAD_BOTTOM + SHK_FORM_PHOTO_PAD_TOP);
    imageView.center = imageViewCenter;
    [self.contentView addSubview:imageView];
    self.clippedImageView = imageView;
    
    if ([[UIApplication sharedApplication] isiOS6OrOlder]) {
        
        UIImage *clip = [UIImage imageNamedFromOurBundle:@"DETweetPaperClip.png"];
        UIImageView *clipView = [[UIImageView alloc] initWithImage:clip];
        clipView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        clipView.center = CGPointMake(self.clippedImageView.center.x + 9, self.clippedImageView.center.y - 35) ;
        [self.contentView addSubview:clipView];
        self.clipImageView = clipView;
    }

    CGRect extensionFrame = CGRectMake(CGRectGetMinX(self.clippedImageView.frame) + SHK_FORM_EXTENSION_PAD,
                                       CGRectGetMinY(self.clippedImageView.frame) + CGRectGetWidth(self.clippedImageView.frame)/2,
                                       CGRectGetWidth(self.clippedImageView.frame) - SHK_FORM_EXTENSION_PAD*2,
                                       CGRectGetHeight(self.clippedImageView.frame)/2);
    UILabel *extension = [[UILabel alloc] initWithFrame:extensionFrame];
    extension.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    extension.textAlignment = NSTextAlignmentCenter;
    extension.text = [self.settings extensionForThumbnail];
    extension.backgroundColor = [UIColor clearColor];
    extension.textColor = [UIColor darkGrayColor];
    extension.font = [UIFont systemFontOfSize:13];
    extension.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:extension];
    self.fileExtension = extension;    
    
    [super setupLayout];
}

- (CGRect)frameForTextview {
    
    CGFloat photoWidth =  [self.settings shouldShowThumbnail] ? self.clippedImageView.frame.size.width : 0;
    CGRect result = CGRectMake(SHK_FORM_CELL_PAD_RIGHT/4,
                              SHK_FORM_TEXT_PAD_TOP,
                              self.contentView.bounds.size.width - SHK_FORM_CELL_PAD_RIGHT/4 - SHK_FORM_CELL_PAD_LEFT/4 - photoWidth,
                              self.contentView.bounds.size.height - SHK_FORM_TEXT_PAD_TOP - SHK_FORM_TEXT_PAD_BOTTOM);
    return result;
}

- (void)setupWithSettings:(SHKFormFieldLargeTextSettings *)settings {
    
    [super setupWithSettings:settings];
    
    self.textView.text = settings.displayValue;
    self.textView.placeholder = settings.label;
    [self checkClipImage];
    [self updateCounter];
}

- (void)checkClipImage {
    
    if ([self.settings shouldShowThumbnail]) {
        
        self.clipImageView.hidden = NO;
        
        self.clippedImageView.hidden = NO;
        [self.settings setupThumbnailOnImageView:self.clippedImageView];
        
        //this must be called after setupThumbnail...
        self.fileExtension.text = [self.settings extensionForThumbnail];
        self.fileExtension.hidden = NO;
        
    } else {
        self.clippedImageView.hidden = YES;
        self.clipImageView.hidden = YES;
        self.fileExtension.hidden = YES;
    }
    self.textView.frame = [self frameForTextview];
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
		  
    NSInteger countNumber = self.settings.maxTextLength - [self.textView.text length];
    NSString *count = [NSString stringWithFormat:@"%li", (long)countNumber];
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
