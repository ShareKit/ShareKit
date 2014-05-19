//
//  SHK1Password.m
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

#import "SHK1Password.h"
#import "SharersCommonHeaders.h"

@implementation SHK1Password

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Open in 1Password");
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

+ (BOOL)canShare {
    
    BOOL is1PasswordInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ophttp://localhost/"]];
	return is1PasswordInstalled;
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
    
    // Convert to a 1Password URL
    NSString *onePasswordScheme = nil;
    if ([self.item.URL.scheme isEqualToString:@"http"]) {
        onePasswordScheme = @"ophttp";
    } else if ([self.item.URL.scheme isEqualToString:@"https"]) {
        onePasswordScheme = @"ophttps";
    }
    
    NSString *absoluteString = [self.item.URL absoluteString];
    NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
    NSString *urlNoScheme =
    [absoluteString substringFromIndex:rangeForScheme.location];
    NSString *chromeURLString =
    [onePasswordScheme stringByAppendingString:urlNoScheme];
    NSURL* actionURL = [NSURL URLWithString:chromeURLString];

	[[UIApplication sharedApplication] openURL:actionURL];
	
	[self sendDidFinish];
	
	return YES;
}

@end