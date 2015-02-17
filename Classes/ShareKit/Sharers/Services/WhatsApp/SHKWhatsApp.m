//
//  SHKWhatsApp.m
//  ShareKit
//
//  Created by Bernhard Hering on 10.06.14.
//
//
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

#import "SHKWhatsApp.h"
#import "SharersCommonHeaders.h"

@implementation SHKWhatsApp

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"WhatsApp");
}

+ (BOOL)canShareURL
{
    return YES;
}

 + (BOOL)canShareText
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
	BOOL isWhatsAppInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://send?text=test"]];
	return isWhatsAppInstalled;
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
    
	NSString *body = self.item.text;
    
    if (!body)
    {
        body = @"";
    }
    
    if (self.item.title) {
        body = [NSString stringWithFormat:@"%@%@",body,self.item.title];
    }

        body= [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if (self.item.URL) {
        NSString *urlStr = SHKEncodeURL(self.item.URL);
        body = [NSString stringWithFormat:@"%@%%20%@",body,urlStr];
    }
  


    // fallback
    if (body == nil)
        body = @"";

    body = [NSString stringWithFormat:@"whatsapp://send?text=%@",body];
    
    NSURL *whatsappURL = [NSURL URLWithString:body];
    
    [[UIApplication sharedApplication] openURL: whatsappURL];
    
    [self sendDidFinish];
    
    return YES;
}



@end
