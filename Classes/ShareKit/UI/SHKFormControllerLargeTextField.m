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

@synthesize delegate, textView, maxTextLength;
@synthesize counter, hasLink, image, imageTextLength;
@synthesize text;

- (void)dealloc 
{
	[textView release];
	[counter release];
	[text release];
	[image release];
	
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id <SHKFormControllerLargeTextFieldDelegate>)aDelegate
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		delegate = aDelegate;
		imageTextLength = 0;
		hasLink = NO;
		maxTextLength = 0;
	}
	return self;
}

- (void)loadView 
{
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	self.textView = [[[UITextView alloc] initWithFrame:self.view.bounds] autorelease];
	textView.delegate = self;
	textView.font = [UIFont systemFontOfSize:15];
	textView.contentInset = UIEdgeInsetsMake(5,5,5,0);
	textView.backgroundColor = [UIColor whiteColor];	
	textView.autoresizesSubviews = YES;
	textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:textView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// save to set the text now
	textView.text = text;
	
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
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
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
	
	textView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
	
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
		
		[self.view addSubview:counter];
		[self layoutCounter];
	}
	
	NSInteger count = (self.image?(self.maxTextLength - self.imageTextLength):self.maxTextLength) - self.textView.text.length;
	counter.text = [NSString stringWithFormat:@"%@%i", self.image ? [NSString stringWithFormat:@"Image %@ ",count>0?@"+":@""]:@"", count];
	
	if (count >= 0) {
		
		self.counter.textColor = [UIColor blackColor];        
		if (self.textView.text.length) self.navigationItem.rightBarButtonItem.enabled = YES; 
		
	} else {
		
		self.counter.textColor = [UIColor redColor];
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}  
}

- (void)ifNoTextDisableSendButton {
	
	if (self.textView.text.length) {
		self.navigationItem.rightBarButtonItem.enabled = YES; 
	} else {
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
}

- (void)layoutCounter
{
	if (![self shouldShowCounter]) return;
	
	counter.frame = CGRectMake(self.textView.bounds.size.width-150-15,
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
