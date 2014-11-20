//
//  SHKActivityIndicator.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/16/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKActivityIndicator.h"

#import <QuartzCore/QuartzCore.h>
#import "Singleton.h"
#import "SHKSharer.h"
#import "SHKMBRoundProgressView.h"
#import "SHK.h"

#define SHKdegreesToRadians(x) (M_PI * x / 180.0)
#define SUB_MESSAGE_MAX_FONT_SIZE 17
#define SUB_MESSAGE_SMALLER_SIZE 12

@interface SHKActivityIndicator ()

@property (nonatomic, weak) SHKSharer *currentSharer;

@property (nonatomic, strong) UILabel *upperMessageLabel;
@property (nonatomic, strong) UILabel *centerMessageLabel;
@property (nonatomic, strong) UILabel *subMessageLabel;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) SHKMBRoundProgressView *progress;
@property (nonatomic, strong) UITapGestureRecognizer *tapToDismissRecognizer;

@end

@implementation SHKActivityIndicator

+ (SHKActivityIndicator *)currentIndicator
{
	DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        
        UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
        NSAssert(keyWindow != nil, @"this means the app is trying to do a ShareKit operation prior to having a UIWindow ready, we don't want the singleton instance to have a messed up frame");
        
		CGFloat width = 160;
		CGFloat height = 160;
		CGRect centeredFrame = CGRectMake(round(keyWindow.bounds.size.width/2 - width/2),
										  round(keyWindow.bounds.size.height/2 - height/2),
										  width,
										  height);
		
		SHKActivityIndicator *result = [[super allocWithZone:NULL] initWithFrame:centeredFrame];
		
		result.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
		result.opaque = NO;
		result.alpha = 0;
		result.layer.cornerRadius = 10;
		result.userInteractionEnabled = NO;
		result.autoresizesSubviews = YES;
		result.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |  UIViewAutoresizingFlexibleTopMargin |  UIViewAutoresizingFlexibleBottomMargin;
		[result setProperRotation:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:result
												 selector:@selector(setProperRotation)
													 name:UIDeviceOrientationDidChangeNotification
												   object:nil];
        return result;
    });
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark Getters & Setters overrides

- (void)setCurrentSharer:(SHKSharer *)currentSharer {
    
    if (_currentSharer && currentSharer && currentSharer != _currentSharer) {
        _currentSharer.quiet = YES; //if there are more sharers sharing concurrently, display only the most recent one. (by shutting up the old one)
    }
    _currentSharer = currentSharer;
}

- (UITapGestureRecognizer *)tapToDismissRecognizer {
    
    if (!_tapToDismissRecognizer) {
        _tapToDismissRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:_tapToDismissRecognizer];
    }
    return _tapToDismissRecognizer;
}

- (UILabel *)centerMessageLabel {
    
    if (!_centerMessageLabel) {
        
        _centerMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,round(self.bounds.size.height/2-50/2),self.bounds.size.width-24,50)];
        _centerMessageLabel.backgroundColor = [UIColor clearColor];
        _centerMessageLabel.opaque = NO;
        _centerMessageLabel.textColor = [UIColor whiteColor];
        _centerMessageLabel.font = [UIFont boldSystemFontOfSize:40];
        _centerMessageLabel.textAlignment = NSTextAlignmentCenter;
        _centerMessageLabel.shadowColor = [UIColor darkGrayColor];
        _centerMessageLabel.shadowOffset = CGSizeMake(1,1);
        _centerMessageLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:_centerMessageLabel];
    }
    return _centerMessageLabel;
}

- (UILabel *)subMessageLabel {
    
    if (!_subMessageLabel) {
        
        _subMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,self.bounds.size.height-45,self.bounds.size.width-24,30)];
        _subMessageLabel.backgroundColor = [UIColor clearColor];
        _subMessageLabel.opaque = NO;
        _subMessageLabel.textColor = [UIColor whiteColor];
        _subMessageLabel.font = [UIFont boldSystemFontOfSize:SUB_MESSAGE_MAX_FONT_SIZE];
        _subMessageLabel.textAlignment = NSTextAlignmentCenter;
        _subMessageLabel.shadowColor = [UIColor darkGrayColor];
        _subMessageLabel.shadowOffset = CGSizeMake(1,1);
        _subMessageLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:_subMessageLabel];
    }
    return _subMessageLabel;
}

- (UILabel *)upperMessageLabel {
    
    
    if (!_upperMessageLabel) {
        
        _upperMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,12,self.bounds.size.width-24,30)];
        _upperMessageLabel.backgroundColor = [UIColor clearColor];
        _upperMessageLabel.opaque = NO;
        _upperMessageLabel.textColor = [UIColor whiteColor];
        _upperMessageLabel.font = [UIFont boldSystemFontOfSize:SUB_MESSAGE_SMALLER_SIZE];
        _upperMessageLabel.textAlignment = NSTextAlignmentCenter;
        _upperMessageLabel.shadowColor = [UIColor darkGrayColor];
        _upperMessageLabel.shadowOffset = CGSizeMake(1,1);
        _upperMessageLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:_upperMessageLabel];
    }
    return _upperMessageLabel;
}

- (UIActivityIndicatorView *)spinner {
    
    if (!_spinner) {
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		_spinner.frame = CGRectMake(round(self.bounds.size.width/2 - _spinner.frame.size.width/2),
                                        round(self.bounds.size.height/2 - _spinner.frame.size.height/2),
                                        _spinner.frame.size.width,
                                        _spinner.frame.size.height);
        [self addSubview:_spinner];
	}
    return _spinner;
}

- (SHKMBRoundProgressView *)progress {
    
    if (!_progress) {
        _progress = [[SHKMBRoundProgressView alloc] init];
        CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        _progress.center = center;
        [self addSubview:_progress];
        [self setupProgress];
        _progress.annular = YES;
    }
    return _progress;
}

- (void)setupProgress
{
    self.tapToDismissRecognizer.enabled = YES;
    self.userInteractionEnabled = YES;
    [self hideSpinner];
    self.upperMessageLabel.text = SHKLocalizedString(@"Tap to dismiss");
}


#pragma mark - Public methods

#pragma mark - Hide

- (void)hide
{
    [self hideForSharer:nil];
}

- (void)hideForSharer:(SHKSharer *)sharer {
    
    self.currentSharer = nil;

    [UIView animateWithDuration:0.4
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self hidden];
                     }];
}

#pragma mark -

- (void)hidden
{
	if (self.alpha > 0)
		return;
	
	[self removeFromSuperview];
}

#pragma mark - Display

- (void)displayActivity:(NSString *)m
{
    [self displayActivity:m forSharer:nil];
}

- (void)displayActivity:(NSString *)m forSharer:(SHKSharer *)sharer {
    
    self.currentSharer = sharer;
    
    [self hideProgressAnimated:NO];

    [self setSubMessage:m];
	[self showSpinner];
	
	[self.centerMessageLabel removeFromSuperview];
	self.centerMessageLabel = nil;
	
	if ([self superview] == nil)
		[self show];
	else
		[self persist];
}

- (void)displayCompleted:(NSString *)m
{
    [self displayCompleted:m forSharer:nil];
}

- (void)displayCompleted:(NSString *)m forSharer:(SHKSharer *)sharer {
    
    self.currentSharer = nil;
    
    [self hideProgressAnimated:NO];
    
    [self setCenterMessage:@"✓"];
	[self setSubMessage:m];
	
	[self hideSpinner];
	
	if ([self superview] == nil)
		[self show];
	else
		[self persist];
    
	[self hideAfterDelay];
}


- (void)showProgress:(CGFloat)progress forSharer:(SHKSharer *)sharer {

    self.currentSharer = sharer;
    
	if ([self superview] == nil)
		[self show];
	else
		[self persist];
    
    self.progress.progress = progress;
}

- (void)hideProgressAnimated:(BOOL)animated {
    
    if (animated) {
        
        [UIView animateWithDuration:0.4f animations:^{
            self.progress.alpha = 0;
        } completion:^(BOOL finished) {
            [self removeProgressUI];
        }];

    } else {
        
        [self removeProgressUI];
    }
}

- (void)removeProgressUI {
    
    [self.progress removeFromSuperview];
    self.progress = nil;
    
    self.tapToDismissRecognizer.enabled = NO;
    self.userInteractionEnabled = NO;
    self.upperMessageLabel.text = nil;
}

#pragma mark Creating Message

- (void)show
{	
	if ([self superview] != [[[UIApplication sharedApplication] delegate] window])
		[[[[UIApplication sharedApplication] delegate] window] addSubview:self];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
	
	[UIView animateWithDuration:0.3
                     animations:^{
                         self.alpha = 1;
                     }];
}

- (void)hideAfterDelay
{
	[self performSelector:@selector(hide) withObject:nil afterDelay:0.6];
}

- (void)persist
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.1];
	
	self.alpha = 1;
	
	[UIView commitAnimations];
}

- (void)setCenterMessage:(NSString *)message
{
    self.centerMessageLabel.text = message;
    
    if (message) {
        [self hideSpinner];
    }
}

- (void)setSubMessage:(NSString *)message
{	
	self.subMessageLabel.text = message;
}
	 
- (void)showSpinner
{
	[self.spinner startAnimating];
}

- (void)hideSpinner
{
	[self.spinner removeFromSuperview];
    self.spinner = nil;
}

- (void)showProgress:(CGFloat)progress {
    
    [self showProgress:progress forSharer:nil];
}

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        self.currentSharer.quiet = YES;
        [self hideForSharer:nil];
        [self hideSpinner];
        [self hideProgressAnimated:YES];
    }
}

#pragma mark -
#pragma mark Rotation

- (void)setProperRotation
{
	[self setProperRotation:YES];
}

- (void)setProperRotation:(BOOL)animated
{
	if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
		return;
	}

	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	
	if (animated)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.3];
	}
	
	if (orientation == UIInterfaceOrientationPortraitUpsideDown)
		self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, SHKdegreesToRadians(180));	
	
	else if (orientation == UIInterfaceOrientationPortrait)
		self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, SHKdegreesToRadians(0)); 
	
	else if (orientation == UIInterfaceOrientationLandscapeRight)
		self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, SHKdegreesToRadians(90));	
	
	else if (orientation == UIInterfaceOrientationLandscapeLeft)
		self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, SHKdegreesToRadians(-90));
	
	if (animated)
		[UIView commitAnimations];
}

@end
