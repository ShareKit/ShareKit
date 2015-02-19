//
//  SHKFormFieldLargeTextSettings.m
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
//
//

#import "SHKFormFieldLargeTextSettings.h"

#import "UIImage+OurBundle.h"
#import <UIActivityIndicator-for-SDWebImage/UIImageView+UIActivityIndicatorForSDWebImage.h>

@interface SHKFormFieldLargeTextSettings ()

/// Shared item. Cell might display its properties, such as image, file etc.
@property (nonatomic, strong) SHKItem *item;
@property (nonatomic) BOOL shouldShowExtension;

@end

@implementation SHKFormFieldLargeTextSettings

+ (SHKFormFieldLargeTextSettings *)label:(NSString *)l key:(NSString *)k start:(NSString *)s item:(SHKItem *)item {

    SHKFormFieldLargeTextSettings *result = [[SHKFormFieldLargeTextSettings alloc] initWithLabel:l key:k type:SHKFormFieldTypeTextLarge start:s];
    result.maxTextLength = 0;
    result.item = item;
    
    return result;
}

- (BOOL)shouldShowThumbnail {
    
    BOOL result = self.item.image || self.item.URL || self.item.file;
    return result;    
}

- (void)setupThumbnailOnImageView:(UIImageView *)imageView {
    
    imageView.image = nil;
    
    switch (self.item.shareType) {
        case SHKShareTypeImage:
        case SHKShareTypeURL:
        case SHKShareTypeText:
            
            if (self.item.image) {
                imageView.image = self.item.image;
            } else if (self.item.URLPictureURI) {
                [imageView setImageWithURL:self.item.URLPictureURI placeholderImage:[UIImage imageNamedFromOurBundle:@"DETweetURLAttachment.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            } else {
                
                if (self.item.URLContentType == SHKURLContentTypeImage) {
                    [imageView setImageWithURL:self.item.URL placeholderImage:[UIImage imageNamedFromOurBundle:@"DETweetURLAttachment.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                } else {
                    imageView.image = [UIImage imageNamedFromOurBundle:@"DETweetURLAttachment.png"];
                }
            }
            break;
            
        case SHKShareTypeFile:
        
            self.shouldShowExtension = NO;
            
            if ([self.item.file hasData]) {
                imageView.image = [UIImage imageWithData:self.item.file.data];
            } else {
                imageView.image = [UIImage imageWithContentsOfFile:self.item.file.path];
            }
            
            if (!imageView.image && self.item.URLPictureURI) {
                  [imageView setImageWithURL:self.item.URLPictureURI placeholderImage:[UIImage imageNamedFromOurBundle:@"DETweetURLAttachment.png"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            } else if (!imageView.image) {
                self.shouldShowExtension = YES;
                imageView.image = [UIImage imageNamedFromOurBundle:@"SHKShareFileIcon.png"];
            }
            
            break;
        default:
            break;
    }
}

- (NSString *)extensionForThumbnail {
    
    if (self.shouldShowExtension) {
        return [self.item.file.filename pathExtension];
    } else {
        return nil;
    }
}

@end
