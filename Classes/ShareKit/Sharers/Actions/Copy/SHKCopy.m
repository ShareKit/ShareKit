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
#import "SharersCommonHeaders.h"

@implementation SHKCopy

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Copy");
}

+ (BOOL)canShareText
{
	return YES;
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

- (void) placeImageOnPasteboard
{
	[[UIPasteboard generalPasteboard] setImage:self.item.image];
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{	
	if (self.item.shareType == SHKShareTypeURL)
		[[UIPasteboard generalPasteboard] setString:self.item.URL.absoluteString];
	else if(self.item.shareType == SHKShareTypeImage)
		[self placeImageOnPasteboard];
    else if (self.item.shareType == SHKShareTypeText)
        [[UIPasteboard generalPasteboard] setString:self.item.text];
	
	// Notify user
	[[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Copied!")];
	
	// Notify delegate, but quietly
	self.quiet = YES;
	[self sendDidFinish];
	
	return YES;
}

@end
