//
//  SHKReadingList.m
//  ShareKit
//
//  Created by Stephen Darlington on 22/05/2014.

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

#import "SHKReadingList.h"
#import "SharersCommonHeaders.h"
#import <SafariServices/SafariServices.h>

@implementation SHKReadingList



#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Add to Safari Reading List");
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
    // the reading list API is only present on iOS 7 and above, so check for its existence
    Class ssReadingList = NSClassFromString(@"SSReadingList");
	return ssReadingList != nil;
}

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{    
    [self sendDidStart];

    NSError* error = nil;
    [[SSReadingList defaultReadingList] addReadingListItemWithURL:self.item.URL
                                                            title:self.item.title
                                                      previewText:self.item.title
                                                            error:&error];

    if (error) {
        [self sendDidFailWithError:error];
    }
    else {
        [self sendDidFinish];
    }
	
	return YES;
}

@end
