//
//  SHKFacebookForm.m
//  ShareKit
//

#import "SHKFormControllerLargeTextField.h"
#import "SHK.h"

@interface SHKFormControllerLargeTextField ()

@property (nonatomic, retain) UILabel *counter;

- (void)layoutCounter;
- (void)updateCounter;
- (void)save;
- (void)keyboardWillShow:(NSNotification *)notification;
- (BOOL)shouldShowCounter;
- (void)ifNoTextDisableSendButton;
- (void)setupBarButtonItems;

@end

@implementation SHKFormControllerLargeTextField

- (void)dealloc 
{
	[_textView release];
	[_counter release];
	[_text release];
	[_image release];
	
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id <SHKFormControllerLargeTextFieldDelegate>)aDelegate
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		_delegate = aDelegate;
		_imageTextLength = 0;
		_hasLink = NO;
		_maxTextLength = 0;
        _allowSendingEmptyMessage = NO;
	}
	return self;
}

- (void)loadView 
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	UITextView *aTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
	aTextView.delegate = self;
	aTextView.font = [UIFont systemFontOfSize:15];
	aTextView.contentInset = UIEdgeInsetsMake(5,5,5,0);
	aTextView.backgroundColor = [UIColor whiteColor];	
	aTextView.autoresizesSubviews = YES;
	aTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:aTextView];
    self.textView = aTextView;
    [aTextView release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// save to set the text now
	self.textView.text = self.text;
	
	[self setupBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	
	[self.textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];	
	
	// Remove observers
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name: UIKeyboardWillShowNotification object:nil];
	
}

- (void)setupBarButtonItems {
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																														target:self
																														action:@selector(cancel)] autorelease];
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Send to %@", [[self.delegate class] sharerTitle]) 
																										style:UIBarButtonItemStyleDone
																									  target:self
																									  action:@selector(save)] autorelease];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect keyboardFrame;
	CGFloat keyboardHeight;
	
	// 3.2 and above
	if (&UIKeyboardFrameEndUserInfoKey)
	{		
		[[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];		
		if ([self interfaceOrientation] == UIDeviceOrientationPortrait || [self interfaceOrientation] == UIDeviceOrientationPortraitUpsideDown) 
			keyboardHeight = keyboardFrame.size.height;
		else
			keyboardHeight = keyboardFrame.size.width;
	}
	
	// < 3.2
	else 
	{
		[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
		keyboardHeight = keyboardFrame.size.height;
	}
	
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
	
	self.textView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
	
	[self layoutCounter];
}
#pragma GCC diagnostic pop

#pragma mark counter updates

- (void)updateCounter
{
	[self ifNoTextDisableSendButton];
	
	if (![self shouldShowCounter]) return;
	
	if (self.counter == nil)
	{
		UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		aLabel.backgroundColor = [UIColor clearColor];
		aLabel.opaque = NO;
		aLabel.font = [UIFont boldSystemFontOfSize:14];
		aLabel.textAlignment = UITextAlignmentRight;		
		aLabel.autoresizesSubviews = YES;
		aLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		self.counter = aLabel;
		[aLabel release];
		
		[self.view addSubview:self.counter];
		[self layoutCounter];
	}
	
	NSString *count;
    NSInteger countNumber = 0;
    
    if (self.maxTextLength) {
        countNumber = (self.image?(self.maxTextLength - self.imageTextLength):self.maxTextLength) - self.textView.text.length;
        count = [NSString stringWithFormat:@"%i", countNumber];
    } else {
        count = @"";
    }
    
    if (self.image) {
        self.counter.text = [NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:@"Image %@ ",countNumber>0?@"+":@""], count];
    } else if (self.hasLink) {
        self.counter.text = [NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:@"Link %@ ",countNumber>0?@"+":@""], count];
    } else {
        self.counter.text = count;
    }
 	
	if (countNumber >= 0) {
		
		self.counter.textColor = [UIColor blackColor];        
		if (self.textView.text.length) self.navigationItem.rightBarButtonItem.enabled = YES; 
		
	} else {
		
		self.counter.textColor = [UIColor redColor];
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}  
}

- (void)ifNoTextDisableSendButton {
	
	if (self.textView.text.length || self.allowSendingEmptyMessage) {
		self.navigationItem.rightBarButtonItem.enabled = YES; 
	} else {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void)layoutCounter
{
	if (![self shouldShowCounter]) return;
	
	self.counter.frame = CGRectMake(self.textView.bounds.size.width-150-15,
										self.textView.bounds.size.height-15-9,
										150,
										15);
	self.textView.contentInset = UIEdgeInsetsMake(5,5,32,0);
}

- (BOOL)shouldShowCounter {
	
	if (self.maxTextLength || self.image || self.hasLink) return YES;
	
	return NO;
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

#pragma mark delegate callbacks 

- (void)cancel
{	
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	[self.delegate sendDidCancel];
}

- (void)save
{	    	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES]; 
	[self.delegate sendForm:self];
}

@end
