    //
//  ExampleShareImage.m
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
//

#import "ExampleShareImage.h"
#import "SHKItem.h"
#import "SHKActionSheet.h"

@implementation ExampleShareImage

@synthesize imageView;

- (void)dealloc
{
	[imageView release];
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
	
	self.imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sanFran.jpg"]];
	
	imageView.frame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
	
	[self.view addSubview:imageView];
	
	[imageView release];
}

- (void)share
{
	SHKItem *item = [SHKItem image:imageView.image title:@"San Francisco"];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

@end
