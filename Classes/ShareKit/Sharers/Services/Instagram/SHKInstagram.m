//
//  SHKInstagram.m
//  PhotoToaster
//
//  Created by Steve Troppoli on 7/19/11.
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

#import "SHKInstagram.h"
#import "SHKConfiguration.h"

@interface SHKInstagram()

@property (nonatomic, retain) UIDocumentInteractionController* dic;
@property BOOL didSend;

@end

@implementation SHKInstagram

- (void)dealloc {
    
	_dic.delegate = nil;
	[_dic release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Instagram");
}

+ (BOOL)canShareURL
{
	return NO;
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

+ (BOOL)canShareOffline
{
	return NO;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
	return [[UIApplication sharedApplication] canOpenURL:instagramURL];
}

+ (BOOL)canAutoShare
{
	return NO;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
	// make a path into documents
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* homePath = [paths objectAtIndex:0];
	NSString* basePath = @"integration/instagram";
	NSString* tmpFileName = @"jumpto.ig";
	
	NSString* dirPath = [NSString stringWithFormat:@"%@/%@", homePath, basePath];
	NSString* docPath = [NSString stringWithFormat:@"%@/%@", dirPath, tmpFileName];
	
	//clear it out and make it fresh
	[[NSFileManager defaultManager] removeItemAtPath:docPath error:nil];
	if ([[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
		UIImage* tmpImg = item.image;
		float tmpCGWidth = CGImageGetWidth(tmpImg.CGImage);
		float tmpCGHeight = CGImageGetHeight(tmpImg.CGImage);
		float smaller = tmpCGWidth < tmpCGHeight ? tmpCGWidth : tmpCGHeight;
		float larger = tmpCGWidth > tmpCGHeight ? tmpCGWidth : tmpCGHeight;
		bool isWide = tmpCGWidth > tmpCGHeight;
		
		// make a draw rect based on the 612 square, scaling up if need be
		smaller = smaller/larger*612;
		larger = 612;
		
		// if we're not passed a proper image, letter box it with white
		if (tmpImg.size.width != 612 || tmpImg.size.height != 612) {
			UIGraphicsBeginImageContext(CGSizeMake(612, 612));
			CGContextRef ctx = UIGraphicsGetCurrentContext();
			[[UIColor colorWithRed:1 green:1 blue:1 alpha:1] set];
			CGContextFillRect(ctx, CGRectMake(0, 0, 612,612));
			CGRect drawRect = CGRectMake(isWide ? 0 :(612 - smaller)/2,
										 isWide ? (612 - smaller)/2 : 0,
										 isWide ? larger : smaller,
										 isWide ? smaller : larger);
			[tmpImg drawInRect:drawRect];
			tmpImg = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
		}
		
		NSData* imgData = [self generateImageData:tmpImg];
		[[NSFileManager defaultManager] createFileAtPath:docPath contents:imgData attributes:nil];
		NSURL* url = [NSURL fileURLWithPath:docPath isDirectory:NO ];
		self.dic = [UIDocumentInteractionController interactionControllerWithURL:url];
		self.dic.UTI = @"com.instagram.exclusivegram";
		NSString *captionString = [NSString stringWithFormat:@"%@%@%@", ([item.title length] ? item.title : @""), ([item.title length] && [item.tags count] ? @" " : @""), [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#" tagSuffix:nil]];
		self.dic.annotation = @{@"InstagramCaption" : captionString};
		self.dic.delegate = self;
		UIView* bestView = self.view;
		if(bestView.window == nil){
			// we haven't been presented yet, so we're not in the hierarchy. On the iPad the DIC is
			// presented in a popover and that really wants a view rooted in a window. Since we
			// set the rootViewController in the controller that presents this one, we can use it
			UIViewController* crvc = [[SHK currentHelper] rootViewForUIDisplay];
			if (crvc != nil && crvc.view.window != nil ) {
				bestView = crvc.view;
			}
		}
		if(bestView.window != nil){
			[self retain];	// retain ourselves until the menu has done it's job or we'll nuke the popup (see documentInteractionControllerDidDismissOpenInMenu)
			[self.dic presentOpenInMenuFromRect:item.popOverSourceRect inView:bestView animated:YES];
		}
		return YES;
	}
	return NO;
}

- (NSData*) generateImageData:(UIImage*)image
{
	return UIImageJPEGRepresentation(image,1.0);
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller{
	if(self.didSend) {
        self.quiet = YES; //so that we do not show "Saved!" prematurely
		[self sendDidFinish];
	} else {
		[self sendDidCancel];
    }
	[self autorelease];
}
- (void) documentInteractionController: (UIDocumentInteractionController *) controller willBeginSendingToApplication: (NSString *) application{
	self.didSend = true;
}
@end
