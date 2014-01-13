//
//  SHKTextMessage.m
//  ShareKit
//
//  Created by Jeremy Lyman on 9/21/10.

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

#import "SHKTextMessage.h"
#import "SharersCommonHeaders.h"

@implementation SHKTextMessage

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"SMS");
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
	return NO;
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
	return [MFMessageComposeViewController canSendText];
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
	
	if (![self validateItem])
		return NO;
	
	return [self sendText]; // Put the actual sending action in another method to make subclassing SHKTextMessage easier
}

- (BOOL)sendText
{	
	MFMessageComposeViewController *composeView = [[MFMessageComposeViewController alloc] init];
	composeView.messageComposeDelegate = self;
  
	NSString *body = self.item.text;
	
	if (!body) {
		
		if (self.item.URL != nil)
		{	
			NSString *urlStr = [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
			if (body != nil)
				body = [body stringByAppendingFormat:@"<br/><br/>%@", urlStr];
			
			else
				body = urlStr;
		}
		
		// fallback
		if (body == nil)
			body = @"";
	}
	[composeView setBody:body];
  
  NSArray *toRecipients = self.item.textMessageToRecipients;
  if (toRecipients)
		[composeView setRecipients:toRecipients];
  
	[[SHK currentHelper] showViewController:composeView];
    [[SHK currentHelper] keepSharerReference:self]; //release is in callback, MFMessageComposeViewController does not retain its delegate
	
	return YES;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller 
				 didFinishWithResult:(MessageComposeResult)result 
{
    switch (result)
	{
		case MessageComposeResultCancelled:
			[self sendDidCancel];
			break;
		case MessageComposeResultSent:
			[self sendDidFinish];
			break;
		case MessageComposeResultFailed:
			[self sendDidFailWithError:nil];
			break;
		default:
			break;
	}
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
    [[SHK currentHelper] removeSharerReference:self]; //retained in [self sendText] method
}


@end
