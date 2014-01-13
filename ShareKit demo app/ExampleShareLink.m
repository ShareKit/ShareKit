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
#import "ShareKit.h"

#define TRY_ENHANCED_URL_SHARE 0

@interface ExampleShareLink () <UIWebViewDelegate>

@property (nonatomic, retain) UIWebView *webView;

@end

@implementation ExampleShareLink

- (void)dealloc
{
    _webView.delegate = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
		self.toolbarItems = [NSArray arrayWithObjects:
								[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
							 [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)],
								[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
								nil
							];
	}
	
	return self;
}

- (void)share
{
    
    /* temporary alternatives for testing */
    //SHKItem *item = [SHKItem URL:[NSURL URLWithString:@"http://ekonomika.sme.sk/c/6987338/smer-dovolil-odborom-aby-presadili-vyssie-platy-aj-bez-suhlasu-firiem.html"] title:@"Big bang" contentType:SHKURLContentTypeVideo];
    /*
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sanFran" ofType:@"jpg"];
    SHKItem *item = [SHKItem filePath:filePath title:@"San Francisco"];
    //item.image = [UIImage imageNamed:@"sanFran.jpg"];
    item.URL = [NSURL URLWithString:@"ekonomika.sme.sk/c/6987338/smer-dovolil-odborom-aby-presadili-vyssie-platy-aj-bez-suhlasu-firiem.html"];
     */
    
    SHKItem *item = nil;
    if (TRY_ENHANCED_URL_SHARE) {
        
        item = [SHKItem URL:[NSURL URLWithString:@"http://www.youtube.com/watch?v=KaOC9danxNo"] title:@"Planet Earth is blue" contentType:SHKURLContentTypeVideo];
        item.URL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=KaOC9danxNo"];
        item.title = @"Lorem ipsum dolor sit amet";
        item.URLPictureURI = [NSURL URLWithString:@"http://www.state.gov/cms_images/india_tajmahal_2003_06_252.jpg"];
        item.URLDescription = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras et posuere mi.";
        item.tags = [NSArray arrayWithObjects:@"apple inc.",@"computers",@"mac", nil];
        
        // bellow are examples how to preload SHKItem with some custom sharer specific settings. You can prefill them ad hoc during each particular SHKItem creation, or set them globally in your configurator, so that every SHKItem is prefilled with the same values. More info in SHKItem.h or DefaultSHKConfigurator.m.
        item.mailToRecipients = [NSArray arrayWithObjects:@"frodo@middle-earth.me", @"gandalf@middle-earth.me", nil];
        item.textMessageToRecipients = [NSArray arrayWithObjects: @"581347615", @"581344543", nil];
        
    } else {
        
        NSString *pageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        item = [SHKItem URL:self.webView.request.URL title:pageTitle contentType:SHKURLContentTypeWebpage];
    }
    
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
	[actionSheet showFromToolbar:self.navigationController.toolbar]; 
}

- (void)loadView 
{ 
	self.webView = [[UIWebView alloc] initWithFrame:CGRectZero];
	self.webView.delegate = self;
	self.webView.scalesPageToFit = YES;
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://apple.com"]]];
		
	self.view = self.webView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

@end
