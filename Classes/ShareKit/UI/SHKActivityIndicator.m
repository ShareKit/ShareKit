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

#define SHKdegreesToRadians(x) (M_PI * x / 180.0)

@implementation SHKActivityIndicator

+ (SHKActivityIndicator *)currentIndicator
{
	DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
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

#pragma mark -

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	
	
}

#pragma mark Creating Message

- (void)show
{	
	if ([self superview] != [[UIApplication sharedApplication] keyWindow]) 
		[[[UIApplication sharedApplication] keyWindow] addSubview:self];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hide) object:nil];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	self.alpha = 1;
	
	[UIView commitAnimations];
}

- (void)hideAfterDelay
{
	[self performSelector:@selector(hide) withObject:nil afterDelay:0.6];
}

- (void)hide
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hidden)];
	
	self.alpha = 0;
	
	[UIView commitAnimations];
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

- (void)hidden
{
	if (self.alpha > 0)
		return;
	
	[self removeFromSuperview];
}

- (void)displayActivity:(NSString *)m
{		
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
	[self setCenterMessage:@"✓"];
	[self setSubMessage:m];
	
	[self.spinner removeFromSuperview];
	self.spinner = nil;
	
	if ([self superview] == nil)
		[self show];
	else
		[self persist];
		
	[self hideAfterDelay];
}

- (void)setCenterMessage:(NSString *)message
{	
	if (message == nil && self.centerMessageLabel != nil)
		self.centerMessageLabel = nil;

	else if (message != nil)
	{
		if (self.centerMessageLabel == nil)
		{
			self.centerMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,round(self.bounds.size.height/2-50/2),self.bounds.size.width-24,50)];
			self.centerMessageLabel.backgroundColor = [UIColor clearColor];
			self.centerMessageLabel.opaque = NO;
			self.centerMessageLabel.textColor = [UIColor whiteColor];
			self.centerMessageLabel.font = [UIFont boldSystemFontOfSize:40];
			self.centerMessageLabel.textAlignment = UITextAlignmentCenter;
			self.centerMessageLabel.shadowColor = [UIColor darkGrayColor];
			self.centerMessageLabel.shadowOffset = CGSizeMake(1,1);
			self.centerMessageLabel.adjustsFontSizeToFitWidth = YES;
			
			[self addSubview:self.centerMessageLabel];
		}
		
		self.centerMessageLabel.text = message;
		[self hideSpinner];
	}
}

- (void)setSubMessage:(NSString *)message
{	
	if (message == nil && self.subMessageLabel != nil)
		self.subMessageLabel = nil;
	
	else if (message != nil)
	{
		if (self.subMessageLabel == nil)
		{
			self.subMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,self.bounds.size.height-45,self.bounds.size.width-24,30)];
			self.subMessageLabel.backgroundColor = [UIColor clearColor];
			self.subMessageLabel.opaque = NO;
			self.subMessageLabel.textColor = [UIColor whiteColor];
			self.subMessageLabel.font = [UIFont boldSystemFontOfSize:17];
			self.subMessageLabel.textAlignment = UITextAlignmentCenter;
			self.subMessageLabel.shadowColor = [UIColor darkGrayColor];
			self.subMessageLabel.shadowOffset = CGSizeMake(1,1);
			self.subMessageLabel.adjustsFontSizeToFitWidth = YES;
			
			[self addSubview:self.subMessageLabel];
		}
		
		self.subMessageLabel.text = message;
	}
}
	 
- (void)showSpinner
{	
	if (self.spinner == nil)
	{
		UIActivityIndicatorView *aSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.spinner = aSpinner;

		self.spinner.frame = CGRectMake(round(self.bounds.size.width/2 - self.spinner.frame.size.width/2),
								round(self.bounds.size.height/2 - self.spinner.frame.size.height/2),
								self.spinner.frame.size.width,
								self.spinner.frame.size.height);		
		
	}
	
	[self addSubview:self.spinner];
	[self.spinner startAnimating];
}

- (void)hideSpinner
{
	[self.spinner removeFromSuperview];
}

- (void)showProgress
{
	if (self.progress == nil)
	{
        self.progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        
		self.progress.frame = CGRectMake(15.0f,
                                   15.0f,
                                   self.bounds.size.width - 30.0f,
                                   self.progress.frame.size.height);
		
	}
	
	[self addSubview:self.progress];
    self.progress.progress = 0;
}

- (void)hideProgress
{
    if(self.progress.alpha < 1 || self.progress.superview == nil) return;
    
    [UIView animateWithDuration:0.35f animations:^{
        self.progress.alpha = 0;
    } completion:^(BOOL finished) {
        [self.progress removeFromSuperview];
        self.progress.alpha = 1;
    }];
}

#pragma mark -
#pragma mark Rotation

- (void)setProperRotation
{
	[self setProperRotation:YES];
}

- (void)setProperRotation:(BOOL)animated
{
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
