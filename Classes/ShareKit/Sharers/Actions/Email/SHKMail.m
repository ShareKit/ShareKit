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


@implementation MFMailComposeViewController (SHK)

- (void)SHKviewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
}

@end



@implementation SHKMail

#import </usr/include/objc/objc-class.h>
void SHKSwizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
		method_exchangeImplementations(origMethod, newMethod);
}

+ (void)initialize
{	
	SHKSwizzle([MFMailComposeViewController class], @selector(viewDidDisappear:), @selector(SHKviewDidDisappear:));
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Email";
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

+ (BOOL)canShareFile
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
	return [MFMailComposeViewController canSendMail];
}

- (BOOL)shouldAutoShare
{
	return YES;
}


#pragma mark -
#pragma mark Share Types

+ (id)shareURL:(NSURL *)url
{
	return [self shareURL:url title:nil];
}

+ (id)shareURL:(NSURL *)url title:(NSString *)title
{
	return 	[self mail:url.absoluteString subject:title to:nil cc:nil bcc:nil attachment:nil attachmentMimeType:nil attachmentFileName:nil];
}

+ (id)shareImage:(UIImage *)image title:(NSString *)title
{
	return 	[self mail:nil subject:title to:nil cc:nil bcc:nil attachment:UIImageJPEGRepresentation(image, 1) attachmentMimeType:@"image/jpeg" attachmentFileName:@"Image.jpg"];
}

+ (id)shareText:(NSString *)text
{
	return 	[self mail:text subject:nil to:nil cc:nil bcc:nil attachment:nil attachmentMimeType:nil attachmentFileName:nil];
}

+ (id)shareFile:(NSData *)file filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title
{
	return [self mail:[NSString stringWithFormat:@"Attached: %@", title]
			  subject:filename to:nil cc:nil bcc:nil 
		   attachment:file attachmentMimeType:mimeType attachmentFileName:filename];
}




#pragma mark -
#pragma mark Share API Methods

+ (id)mail:(NSString *)body
	subject:(NSString *)subject 
		 to:(NSArray *)to 
		 cc:(NSArray *)cc 
		bcc:(NSArray *)bcc
 attachment:(NSData *)attachment
attachmentMimeType:(NSString *)mimeType
attachmentFileName:(NSString *)filename
{
	MFMailComposeViewController *mailController = [[[MFMailComposeViewController alloc] init] autorelease];
	mailController.mailComposeDelegate = [[[self alloc] init] autorelease];
	
	[mailController setSubject:subject];
	[mailController setMessageBody:body isHTML:YES];
	
	[mailController setToRecipients:to];
	[mailController setCcRecipients:cc];
	[mailController setBccRecipients:bcc];
	
	if (attachment)
		[mailController addAttachmentData:attachment mimeType:mimeType fileName:filename];
	
	// How to allow devs to attach present the view how they want o
	[[SHK currentHelper] showViewController:mailController];
	
	return mailController;
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}


@end
