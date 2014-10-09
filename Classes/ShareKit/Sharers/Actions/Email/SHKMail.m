//
//  SHKMail.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

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

#import "SHKMail.h"
#import "SharersCommonHeaders.h"

#define MAX_ATTACHMENT_SIZE 10*1024*1024 //10mb

@implementation SHKMail

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Email");
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

+ (BOOL)canShareVideo
{
    return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file {
    
    /*
     * Limiting to 10MB, based on common max attachment sizes listed here:
     * http://en.wikipedia.org/wiki/Email_attachment
     * http://help.sizablesend.com/what-are-the-attachment-size-limits-of-major-email-providers/
     */
    
    BOOL result = file.size <= MAX_ATTACHMENT_SIZE;
    return result;
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
	return [MFMailComposeViewController canSendMail];
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
	
	return [self sendMail]; // Put the actual sending action in another method to make subclassing SHKMail easier
}

- (BOOL)sendMail
{	
	MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
	if (!mailController) {
		// e.g. no mail account registered (will show alert)
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		return YES;
	}
	
    [[SHK currentHelper] keepSharerReference:self]; //must retain, because mailController does not retain its delegates. Released in callback.
	mailController.mailComposeDelegate = self;
	mailController.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,mailController);
	
	NSString *body = self.item.text ? self.item.text : @"";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	BOOL isHTML = self.item.isMailHTML || self.item.isHTMLText;
#pragma clang diagnostic pop
    NSString *separator = (isHTML ? @"<br/><br/>" : @"\n\n");
		
		if (self.item.URL != nil)
		{
			NSString *urlStr = [self.item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			
            if ([body length] > 0) {
                body = [body stringByAppendingFormat:@"%@%@", separator, urlStr];
            } else {
                body = [body stringByAppendingFormat:@"%@", urlStr];
            }
		}
		
		if (self.item.file)
		{
			NSString *attachedStr = SHKLocalizedString(@"Attached: %@", self.item.title ? self.item.title : self.item.file.filename);
			
            if ([body length] > 0) {
                body = [body stringByAppendingFormat:@"%@%@", separator, attachedStr];
            } else {
                body = [body stringByAppendingFormat:@"%@", attachedStr];
            }
            		}
		
		// fallback
		if (body == nil)
			body = @"";
		
		// sig
		if (self.item.mailShareWithAppSignature)
		{
			body = [body stringByAppendingString:separator];
			body = [body stringByAppendingString:SHKLocalizedString(@"Sent from %@", SHKCONFIG(appName))];
		}
	
	if (self.item.file)
		[mailController addAttachmentData:self.item.file.data mimeType:self.item.file.mimeType fileName:self.item.file.filename];
	
	NSArray *toRecipients = self.item.mailToRecipients;
    if (toRecipients)
		[mailController setToRecipients:toRecipients];
    
	if (self.item.image){
        
        CGFloat jpgQuality = self.item.mailJPGQuality;
        [mailController addAttachmentData:UIImageJPEGRepresentation(self.item.image, jpgQuality) mimeType:@"image/jpeg" fileName:@"Image.jpg"];
	}
	
	[mailController setSubject:self.item.title];
	[mailController setMessageBody:body isHTML:isHTML];
			
	[[SHK currentHelper] showViewController:mailController];
	
	return YES;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	switch (result) 
	{
		case MFMailComposeResultSent:
			[self sendDidFinish];
			break;
		case MFMailComposeResultSaved:
			[self sendDidFinish];
			break;
		case MFMailComposeResultCancelled:
			[self sendDidCancel];
			break;
		case MFMailComposeResultFailed:
			[self sendDidFailWithError:nil];
			break;
	}
	[[SHK currentHelper] removeSharerReference:self];
}

@end