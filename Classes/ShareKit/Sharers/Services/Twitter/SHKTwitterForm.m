//
//  SHKTwitterForm.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/22/10.

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

#import "SHKTwitterForm.h"
#import "SHK.h"

@interface SHKTwitterForm ()

@property (nonatomic, retain) UILabel *counter;

- (void)layoutCounter;
- (void)updateCounter;

@end

@implementation SHKTwitterForm

@synthesize counter;
@synthesize hasAttachment;

- (void)dealloc 
{
	[counter release];
    [super dealloc];
}

- (void)keyboardWillShow:(NSNotification *)notification
{	
	[super keyboardWillShow:notification];
	[self layoutCounter];
}

#pragma mark -

- (void)updateCounter
{
	if (counter == nil)
	{
		UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.counter = aLabel;
        [aLabel release];
		counter.backgroundColor = [UIColor clearColor];
		counter.opaque = NO;
		counter.font = [UIFont boldSystemFontOfSize:14];
		counter.textAlignment = UITextAlignmentRight;
		
		counter.autoresizesSubviews = YES;
		counter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[self.view addSubview:counter];
		[self layoutCounter];
	}
	
	int count = (hasAttachment?115:140) - self.textView.text.length;
	counter.text = [NSString stringWithFormat:@"%@%i", hasAttachment ? @"Image + ":@"" , count];
	counter.textColor = count >= 0 ? [UIColor blackColor] : [UIColor redColor];
}

- (void)layoutCounter
{
	counter.frame = CGRectMake(self.textView.bounds.size.width-150-15,
							   self.textView.bounds.size.height-15-9,
							   150,
							   15);
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

#pragma mark -

- (void)save
{	
	if (self.textView.text.length > (hasAttachment?115:140))
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is too long")
									 message:SHKLocalizedString(@"Twitter posts can only be 140 characters in length.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	[super save];
}

@end
