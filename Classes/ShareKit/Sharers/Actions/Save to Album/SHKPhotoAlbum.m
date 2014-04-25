//
//  SHKPhotoAlbum.m
//  ShareKit
//
//  Created by Richard Johnson on 7/22/10.

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

#import "SHKPhotoAlbum.h"
#import "SharersCommonHeaders.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

typedef void (^SHKPhotoSharerCompletionBlock)(NSURL *assetURL, NSError *error);

@implementation SHKPhotoAlbum

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Save to Photo Album");
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file {
    
    if ([file.mimeType hasPrefix:@"image/"]) {
        
        return YES;

    } else if ([file.mimeType hasPrefix:@"video/"] && !file.hasPath) {
        
        //if file is in-memory only, it would have to be synchronously saved to disc to obtain path. This is unacceptable long process, it would pause share sheet displaying.
        return NO;
        
    } else if ([file.mimeType hasPrefix:@"video/"]) {
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        BOOL result = [library videoAtPathIsCompatibleWithSavedPhotosAlbum:file.URL];
        return result;
        
    } else {
        
        return NO;
    }
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

- (BOOL)send
{	
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    switch (self.item.shareType) {
            
        case SHKShareTypeImage:
            
            [self writeImageToAlbum];
            break;
            
        case SHKShareTypeFile:
            
            if ([self.item.file.mimeType hasPrefix:@"video"]) {
                [library writeVideoAtPathToSavedPhotosAlbum:self.item.file.URL completionBlock:[self completionBlock]];
            } else {
                [self writeImageToAlbum];
            }
            break;
        default:
            break;
    }
    
	return YES;
}

- (void)writeImageToAlbum {
    
    UIImage *imageToShare = nil;
    
    switch (self.item.shareType) {
        case SHKShareTypeImage:
            imageToShare = self.item.image;
            break;
        case SHKShareTypeFile:
            imageToShare = [UIImage imageWithData:self.item.file.data];
        default:
            break;
    }
    
    NSDictionary *metadata = [self extractExifFrom:self.item.file.data];
    
    ALAssetsLibrary* assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary writeImageToSavedPhotosAlbum:imageToShare.CGImage
                                       metadata:metadata
                                completionBlock:[self completionBlock]];
}

- (NSDictionary *)extractExifFrom :(NSData *)imageData {
    
    if (!imageData) return nil;

    NSDictionary *result = nil;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    
    if (source)
    {
        CFDictionaryRef metadataRef = CGImageSourceCopyPropertiesAtIndex (source, 0, NULL);
        if (metadataRef)
        {
            NSDictionary *immutableMetadata = (__bridge NSDictionary *)metadataRef;
            if (immutableMetadata)
            {
                result = [NSDictionary dictionaryWithDictionary : (__bridge NSDictionary *)metadataRef];
            }
            CFRelease (metadataRef);
        }
        CFRelease(source);
        source = nil;
    }
    return result;
}

- (SHKPhotoSharerCompletionBlock)completionBlock {
    
    SHKPhotoSharerCompletionBlock result = ^(NSURL *assetURL, NSError *error) {
       
        if (assetURL) {
            [self sendDidFinish];
        } else {
            [self sendShowSimpleErrorAlert];
            SHKLog(@"Error while saving video: %@", [error description]);
        }
    };
    return result;
}

@end
