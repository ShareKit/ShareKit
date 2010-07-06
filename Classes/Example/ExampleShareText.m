    //
//  ExampleShareText.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.
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

#import "ExampleShareText.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"

@implementation ExampleShareText

@synthesize textView;

- (void)dealloc
{
	[textView release];
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
		self.toolbarItems = [NSArray arrayWithObjects:
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)] autorelease],
							 [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
							 nil
							 ];
	}
	
	return self;
}

- (void)loadView 
{
	[super loadView];
	
	self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height)];
	[self.view addSubview:textView];
	
	textView.text = @"This is a chunk of text.  If you highlight it, you'll be able to share the selection.  If you tap the share button below, it will share all of it.";
	textView.editable = NO;
	
	[textView release];
}

- (void)share
{	
	NSString *text;
	
	if (textView.selectedRange.length > 0)
		text = [textView.text substringWithRange:textView.selectedRange];
	
	else
		text = textView.text;

	
	SHKItem *item = [SHKItem text:text];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


@end
