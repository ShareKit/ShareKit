//
//  SHKFoursquareV2OAuthView.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/26/11.
//  Sponsored by Twoppy
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

#import "SHKFoursquareV2OAuthView.h"

@implementation SHKFoursquareV2OAuthView

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{		
	if ([request.URL.absoluteString rangeOfString:[delegate authorizeCallbackURL].absoluteString].location != NSNotFound)
	{
		// Get query
		NSMutableDictionary *queryParams = nil;
		if (request.URL.fragment != nil)
		{
			queryParams = [NSMutableDictionary dictionaryWithCapacity:0];
			NSArray *vars = [request.URL.fragment componentsSeparatedByString:@"&"];
			NSArray *parts;
			for(NSString *var in vars)
			{
				parts = [var componentsSeparatedByString:@"="];
				if (parts.count == 2)
					[queryParams setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			}
		}
		
		[delegate tokenAuthorizeView:self didFinishWithSuccess:YES queryParams:queryParams error:nil];
		self.delegate = nil;
		
		return NO;
	}
	
	return YES;
}


@end
