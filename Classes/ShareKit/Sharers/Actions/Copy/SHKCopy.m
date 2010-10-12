//
//  SHKCopy.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/20/10.

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

#import "SHKCopy.h"


@implementation SHKCopy

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Copy");
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareImage
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

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)send {	
	
	if (item.shareType == SHKShareTypeURL) {
		if(kSHKCopyShouldShortenURLs)
			[self shortenURL];
		else
			[self copyToPasteboard:item.URL.absoluteString];
	}
	else {
		[[UIPasteboard generalPasteboard] setImage:item.image];
		[[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Copied!")];
	}
	return YES;
}

- (void)shortenURLFinished:(SHKRequest *)aRequest {
	[super shortenURLFinished:aRequest];
	
	NSString *urlStr = [item customValueForKey:@"shortenURL"]; 
	if(urlStr==nil||urlStr.length==0) 
		urlStr = item.URL.absoluteString;
	[self copyToPasteboard:urlStr];
}

- (void)copyToPasteboard:(NSString *)urlStr {
	[[UIPasteboard generalPasteboard] setString:urlStr];
	[[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Copied!")];
}



@end
