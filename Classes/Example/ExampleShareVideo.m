//
//  ExampleShareVideo.m
//  ShareKit
//
//  Created by Dan Gustafsson on 31/01/2012.
//

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


#import "ExampleShareVideo.h"
#import "SHK.h"
#import "SHKActionSheet.h"

@implementation ExampleShareVideo

@synthesize webView;

- (void)dealloc
{
	[webView release];
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
	self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	webView.delegate = self;
	webView.scalesPageToFit = YES;
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"IMG_0458.m4v"]]]];
	
	self.view = webView;
}

- (void)share
{
	NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"IMG_0458.m4v"];
	NSData *videoFile = [NSData dataWithContentsOfFile:filePath];
	
	SHKItem *item = [SHKItem video:videoFile filename:@"cool_video.m4v" title:@"Cool video"];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
	[SHK setRootViewController:self];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

@end
