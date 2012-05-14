    //
//  ExampleShareLink.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

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

#import "ExampleShareLink.h"
#import "SHK.h"

@implementation ExampleShareLink

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

- (void)share
{
	SHKItem *item = [SHKItem URL:webView.request.URL title:[webView pageTitle]];
    //item.facebookURLSharePictureURI = @"http://www.state.gov/cms_images/india_tajmahal_2003_06_252.jpg";
    //item.facebookURLShareDescription = @"description text";
    item.mailToRecipients = [NSArray arrayWithObjects:@"frodo@middle-earth.me", @"gandalf@middle-earth.me", nil];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
	[actionSheet showFromToolbar:self.navigationController.toolbar]; 
}

- (void)loadView 
{ 
	self.webView = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
	webView.delegate = self;
	webView.scalesPageToFit = YES;
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.com"]]];
		
	self.view = webView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

@end
