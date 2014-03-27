//
//  SHKImgurOAuthView.m
//  ShareKit
//
//  Created by Andrew Shu on 3/21/14.
//
//

#import "SHKImgurOAuthView.h"

#import "Debug.h"
#import "SHK.h"

@interface SHKImgurOAuthView ()

@end

@implementation SHKImgurOAuthView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if ([request.URL.absoluteString rangeOfString:[self.delegate authorizeCallbackURL].absoluteString options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		// Get fragment instead of query, since OAuth 2.0 response_type=token
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
