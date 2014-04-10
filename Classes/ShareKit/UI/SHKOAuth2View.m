//
//  SHKImgurOAuthView.m
//  ShareKit
//
//  Created by Andrew Shu on 3/21/14.
//
//

#import "SHKOAuth2View.h"

#import "Debug.h"
#import "SHK.h"

@implementation SHKOAuth2View

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString rangeOfString:[self.delegate authorizeCallbackURL].absoluteString options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		NSMutableDictionary *queryParams = nil;
		if ([request.URL.absoluteString rangeOfString:@"redirect"].location != NSNotFound)
        {
            //if user authenticates via 3rd party service (Google, Facebook etc)
            return YES;
        }
        else if (request.URL.fragment != nil)
		{
			// Get fragment instead of query, since OAuth 2.0 response_type=token
            queryParams = [NSMutableDictionary dictionaryWithCapacity:0];
			NSArray *vars = [request.URL.fragment componentsSeparatedByString:@"&"];
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
            // cancel
            [self.delegate tokenAuthorizeCancelledView:self];
            [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
        }
		
        self.delegate = nil;
		return NO;
	}
	
	return YES;
}

@end
