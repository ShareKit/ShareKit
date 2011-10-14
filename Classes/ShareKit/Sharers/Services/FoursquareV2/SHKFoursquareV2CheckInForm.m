//
//  SHKFoursquareV2CheckInForm.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/26/11.
//  Sponsored by Twoppy
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

#import "SHKFoursquareV2CheckInForm.h"

@implementation SHKFoursquareV2CheckInForm

@synthesize delegate = _delegate;

- (void)dealloc
{
    self.delegate = nil;
    
    [_textView release];
    [_counter release];   
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) 
	{		
        self.title = SHKLocalizedString(@"Foursquare");
        
//		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
//																							  target:self
//																							  action:@selector(cancel)];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Check In")
																				  style:UIBarButtonItemStyleDone
																				 target:self
																				 action:@selector(save)];
    }
    return self;
}

- (id)initWithDelegate:(SHKFoursquareV2*)delegate
{
    self = [self initWithNibName:nil bundle:nil];
    
    if (self) {
        self.delegate = delegate;
    }
    
    return self;
}

- (void)loadView 
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	_textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	_textView.delegate = self;
	_textView.font = [UIFont systemFontOfSize:15];
	_textView.contentInset = UIEdgeInsetsMake(5,5,0,0);
	_textView.backgroundColor = [UIColor whiteColor];	
	_textView.autoresizesSubviews = YES;
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.text = self.delegate.item.text;
	
	[self.view addSubview:_textView];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	
	[_textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];	
	
	// Remove observers
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name: UIKeyboardWillShowNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)layoutCounter
{
	_counter.frame = CGRectMake(_textView.bounds.size.width-150-15,
                                _textView.bounds.size.height-15-9,
                                150,
                                15);
}

//#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect keyboardFrame;
	CGFloat keyboardHeight;
	
	// 3.2 and above
	/*if (UIKeyboardFrameEndUserInfoKey)
	 {		
	 [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];		
	 if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) 
	 keyboardHeight = keyboardFrame.size.height;
	 else
	 keyboardHeight = keyboardFrame.size.width;
	 }
	 
	 // < 3.2
	 else 
	 {*/
    
	[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
	keyboardHeight = keyboardFrame.size.height;
	//}
	
	// Find the bottom of the screen (accounting for keyboard overlay)
	// This is pretty much only for pagesheet's on the iPad
	UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL inLandscape = orient == UIInterfaceOrientationLandscapeLeft || orient == UIInterfaceOrientationLandscapeRight;
	BOOL upsideDown = orient == UIInterfaceOrientationPortraitUpsideDown || orient == UIInterfaceOrientationLandscapeRight;
	
	CGPoint topOfViewPoint = [self.view convertPoint:CGPointZero toView:nil];
	CGFloat topOfView = inLandscape ? topOfViewPoint.x : topOfViewPoint.y;
	
	CGFloat screenHeight = inLandscape ? [[UIScreen mainScreen] applicationFrame].size.width : [[UIScreen mainScreen] applicationFrame].size.height;
	
	CGFloat distFromBottom = screenHeight - ((upsideDown ? screenHeight - topOfView : topOfView ) + self.view.bounds.size.height) + ([UIApplication sharedApplication].statusBarHidden || upsideDown ? 0 : 20);							
	CGFloat maxViewHeight = self.view.bounds.size.height - keyboardHeight + distFromBottom;
	
	_textView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
	[self layoutCounter];
}
//#pragma GCC diagnostic pop  

#pragma mark -

- (void)updateCounter
{
	if (_counter == nil)
	{
		_counter = [[UILabel alloc] initWithFrame:CGRectZero];
		_counter.backgroundColor = [UIColor clearColor];
		_counter.opaque = NO;
		_counter.font = [UIFont boldSystemFontOfSize:14];
		_counter.textAlignment = UITextAlignmentRight;
		
		_counter.autoresizesSubviews = YES;
		_counter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[self.view addSubview:_counter];
		[self layoutCounter];
	}
	
	int count = 140 - _textView.text.length;
	_counter.text = [NSString stringWithFormat:@"%i", count];
	_counter.textColor = count >= 0 ? [UIColor blackColor] : [UIColor redColor];
}

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


#pragma mark Private

- (void)save
{
	if (_textView.text.length > 700)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is too long")
									 message:SHKLocalizedString(@"Foursquare posts can only be 140 characters in length.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	else if (_textView.text.length == 0)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is empty")
									 message:SHKLocalizedString(@"You must enter a message in order to post.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
    
    [_textView resignFirstResponder];
    
    self.delegate.item.text = _textView.text;
    
    [self.delegate startCheckInRequest];
}

- (void)cancel
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[self.delegate sendDidCancel];
}

@end
