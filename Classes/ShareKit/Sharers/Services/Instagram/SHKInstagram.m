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
#import "SharersCommonHeaders.h"

#define MAX_RESOLUTION_IPHONE_3GS 1536.0f
#define MAX_RESOLUTION_IPHONE_4 1936.0f

@interface SHKInstagram()

@property (nonatomic, strong) UIDocumentInteractionController* dic;
@property BOOL didSend;

@end

@implementation SHKInstagram

- (void)dealloc {
    
	_dic.delegate = nil;
	
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
	NSString* tmpFileName;
    if ([SHKCONFIG(instagramOnly) boolValue]) {
        tmpFileName = @"jumpto.igo";
    } else {
        tmpFileName = @"jumpto.ig";
    }
	
	NSString* dirPath = [NSString stringWithFormat:@"%@/%@", homePath, basePath];
	NSString* docPath = [NSString stringWithFormat:@"%@/%@", dirPath, tmpFileName];
	
	//clear it out and make it fresh
	[[NSFileManager defaultManager] removeItemAtPath:docPath error:nil];
	if ([[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
		UIImage* tmpImg = self.item.image;
        
        if(tmpImg.size.width != tmpImg.size.height && [SHKCONFIG(instagramLetterBoxImages) boolValue]){
            float size = tmpImg.size.width > tmpImg.size.height ? tmpImg.size.width : tmpImg.size.height;
            CGFloat maxPhotoSize = [self maxPhotoSize];
            if(size > maxPhotoSize) size = maxPhotoSize;
            tmpImg = [self imageByScalingImage:tmpImg proportionallyToSize:CGSizeMake(size,size)];
        }
		
		NSData* imgData = [self generateImageData:tmpImg];
		[[NSFileManager defaultManager] createFileAtPath:docPath contents:imgData attributes:nil];
		NSURL* url = [NSURL fileURLWithPath:docPath isDirectory:NO ];
		self.dic = [UIDocumentInteractionController interactionControllerWithURL:url];
        if (SHKCONFIG(instagramOnly)) {
            self.dic.UTI = @"com.instagram.exclusivegram";
        } else {
            self.dic.UTI = @"com.instagram.photo";
        }
		NSString *captionString = [NSString stringWithFormat:@"%@%@%@", ([self.item.title length] ? self.item.title : @""), ([self.item.title length] && [self.item.tags count] ? @" " : @""), [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#" tagSuffix:nil]];
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
			[[SHK currentHelper] keepSharerReference:self];	// retain ourselves until the menu has done it's job or we'll nuke the popup (see documentInteractionControllerDidDismissOpenInMenu)
			[self.dic presentOpenInMenuFromRect:self.item.popOverSourceRect inView:bestView animated:YES];
		}
		return YES;
	}
	return NO;
}

- (CGFloat)maxPhotoSize {
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (scale == 1.0f) {
        return MAX_RESOLUTION_IPHONE_3GS;
    } else {
        return MAX_RESOLUTION_IPHONE_4;
    }
}

- (UIImage *)imageByScalingImage:(UIImage*)image proportionallyToSize:(CGSize)targetSize {
    
    UIImage *sourceImage = image;
    UIImage *newImage = nil;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor)
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        
        if (widthFactor < heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else if (widthFactor > heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    
    // this is actually the interesting part:
    
    UIGraphicsBeginImageContext(targetSize);
    
    [(UIColor*)SHKCONFIG(instagramLetterBoxColor) set];
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0,0,targetSize.width,targetSize.height));
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if(newImage == nil) NSLog(@"could not scale image");
    
    return newImage ;
}

- (NSData*)generateImageData:(UIImage*)image
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
	[[SHK currentHelper] removeSharerReference:self];
}
- (void) documentInteractionController: (UIDocumentInteractionController *) controller willBeginSendingToApplication: (NSString *) application{
	self.didSend = true;
}
@end
