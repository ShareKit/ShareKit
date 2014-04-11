    //
//  SHKTwitterAuthView.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

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

#import "SHKOAuthView.h"

#import "SHK.h"
#import "SHKOAuthSharer.h"

@interface SHKOAuthView ()

@property (strong, nonatomic) NSURL *authorizeURL;

@end

@implementation SHKOAuthView

- (id)initWithURL:(NSURL *)authorizeURL delegate:(id <SHKOAuthViewDelegate>)d
{
    if ((self = [super initWithNibName:nil bundle:nil])) 
	{
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																								  target:self
																								  action:@selector(cancel)] animated:NO];
		_delegate = d;
        _authorizeURL = authorizeURL;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIWebView *aWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    aWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aWebView.delegate = self;
    aWebView.scalesPageToFit = YES;
    aWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    [aWebView loadRequest:[NSURLRequest requestWithURL:self.authorizeURL]];
    self.webView = aWebView;
    [self.view addSubview:aWebView];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{		
	if ([request.URL.absoluteString rangeOfString:[self.delegate authorizeCallbackURL].absoluteString options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		// Get query
		NSMutableDictionary *queryParams = nil;
		if (request.URL.query != nil)
		{
			queryParams = [NSMutableDictionary dictionaryWithCapacity:0];
			NSArray *vars = [request.URL.query componentsSeparatedByString:@"&"];
			NSArray *parts;
			for(NSString *var in vars)
			{
				parts = [var componentsSeparatedByString:@"="];
				if (parts.count == 2)
					[queryParams setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			}
            [self.delegate tokenAuthorizeView:self didFinishWithSuccess:YES queryParams:queryParams error:nil];
		}
        else
        {
            [self cancel];
        }
		
        self.delegate = nil;
		return NO;
	}
	
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[self startSpinner];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{	
    //some web pages do not adjust to current size of a view, but apparently size of a screen(?). This helps them to keep disciplined.
    NSString *javaFormatString = @"document.querySelector('meta[name=viewport]').setAttribute('content', 'width=%d;', false); ";
    [aWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:javaFormatString, (int)aWebView.frame.size.width]];
    
    [self stopSpinner];
	
	// Extra sanity check for Twitter OAuth users to make sure they are using BROWSER with a callback instead of pin based auth
	if ([self.webView.request.URL.host isEqualToString:@"api.twitter.com"] && [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('oauth_pin').innerHTML"].length)
		[self.delegate tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:[SHK error:@"Your SHKTwitter config is incorrect.  You must set your application type to Browser and define a callback url.  See SHKConfig.h for more details"]];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{	
	if ([error code] != NSURLErrorCancelled && [error code] != 102 && [error code] != NSURLErrorFileDoesNotExist)
	{
		[self stopSpinner];
		[self.delegate tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:error];
	}
}

- (void)startSpinner
{
	if (self.spinner == nil)
	{
		UIActivityIndicatorView *aSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner = aSpinner;
        //self.spinner.color = self.view.tintColor;

		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.spinner] animated:NO];
		self.spinner.hidesWhenStopped = YES;
	}
	
	[self.spinner startAnimating];
}

- (void)stopSpinner
{
	[self.spinner stopAnimating];
}


#pragma mark - View Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)cancel
{
	[self.delegate tokenAuthorizeCancelledView:self];
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

@end
