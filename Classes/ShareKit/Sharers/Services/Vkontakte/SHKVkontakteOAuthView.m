//
//  SHKVkontakteOAuthView.m
//  ShareKit
//
//  Created by Alterplay Team on 05.12.11.
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

#import "SHKVkontakteOAuthView.h"

#import "SHKVkontakte.h"
#import "SHK.h"
#import "Debug.h"

@implementation SHKVkontakteOAuthView
@synthesize vkWebView, appID, delegate;

- (void) dealloc {
	vkWebView.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
}

- (void) closeView
{
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void) addCloseButton
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(closeView)];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];
	
    [self addCloseButton];
    
	if(!vkWebView)
	{
		self.vkWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
		vkWebView.delegate = self;
		vkWebView.scalesPageToFit = YES;
		self.vkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:vkWebView];
	}
	
	if(!appID) 
	{
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		return;
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString *authLink = [NSString stringWithFormat:@"http://api.vk.com/oauth/authorize?client_id=%@&scope=wall,photos,friends,offline,docs&redirect_uri=http://api.vk.com/blank.html&display=touch&response_type=token", appID];
    NSURL *url = [NSURL URLWithString:authLink];

    [vkWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[vkWebView stopLoading];
	vkWebView.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Web View Delegate

- (BOOL)webView:(UIWebView *)aWbView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
	NSURL *URL = [request URL];

	if ([[URL absoluteString] isEqualToString:@"http://api.vk.com/blank.html#error=access_denied&error_reason=user_denied&error_description=User%20denied%20your%20request"]) {
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		return NO;
	}
	SHKLog(@"Request: %@", [URL absoluteString]); 
	return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
	
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {

	if ([vkWebView.request.URL.absoluteString rangeOfString:@"access_token"].location != NSNotFound) {
		NSString *accessToken = [SHKVkontakteOAuthView stringBetweenString:@"access_token="
																						andString:@"&" 
																					innerString:[[[webView request] URL] absoluteString]];
		
		NSArray *userAr = [[[[webView request] URL] absoluteString] componentsSeparatedByString:@"&user_id="];
		NSString *user_id = [userAr lastObject];
		SHKLog(@"User id: %@", user_id);
		if(user_id){
			[[NSUserDefaults standardUserDefaults] setObject:user_id forKey:kSHKVkonakteUserId];
		}
		
		if(accessToken){
			[[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kSHKVkontakteAccessTokenKey];

			[[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] dateByAddingTimeInterval:86400] forKey:kSHKVkontakteExpiryDateKey];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		SHKLog(@"vkWebView response: %@",[[[webView request] URL] absoluteString]);
		[(SHKVkontakte *)delegate authComplete];
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	} else if ([vkWebView.request.URL.absoluteString rangeOfString:@"error"].location != NSNotFound) {
		SHKLog(@"Error: %@", vkWebView.request.URL.absoluteString);
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	}
	
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	
	SHKLog(@"vkWebView Error: %@", [error localizedDescription]);
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

#pragma mark - Methods

+ (NSString*)stringBetweenString:(NSString*)start
                       andString:(NSString*)end 
                     innerString:(NSString*)str 
{
	NSScanner* scanner = [NSScanner scannerWithString:str];
	[scanner setCharactersToBeSkipped:nil];
	[scanner scanUpToString:start intoString:NULL];
	if ([scanner scanString:start intoString:NULL]) {
		NSString* result = nil;
		if ([scanner scanUpToString:end intoString:&result]) {
			return result;
		}
	}
	return nil;
}

@end
