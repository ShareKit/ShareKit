//
//  SHKChrome.m
//  ShareKit
//
//  Created by Stephen Darlington on 18/05/2014.

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

#import "SHKChrome.h"
#import "SharersCommonHeaders.h"

@implementation SHKChrome



#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Open in Chrome");
}

+ (BOOL)canShareURL
{
    return YES;
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	BOOL isChromeInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://localhost/"]];
	return isChromeInstalled;
}

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	self.quiet = YES;
    
    // Convert to a Chrome URL
    NSString *chromeScheme = nil;
    if ([self.item.URL.scheme isEqualToString:@"http"]) {
        chromeScheme = @"googlechrome";
    } else if ([self.item.URL.scheme isEqualToString:@"https"]) {
        chromeScheme = @"googlechromes";
    }
    
    NSString *absoluteString = [self.item.URL absoluteString];
    NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
    NSString *urlNoScheme =
    [absoluteString substringFromIndex:rangeForScheme.location];
    NSString *chromeURLString =
    [chromeScheme stringByAppendingString:urlNoScheme];
    NSURL* actionURL = [NSURL URLWithString:chromeURLString];

	[[UIApplication sharedApplication] openURL:actionURL];
	
	[self sendDidFinish];
	
	return YES;
}

@end
