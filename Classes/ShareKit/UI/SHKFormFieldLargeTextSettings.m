//
//  SHKFormFieldLargeTextSettings.m
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
//
//

#import "SHKFormFieldLargeTextSettings.h"

@interface SHKFormFieldLargeTextSettings ()

/// Shared item. Cell might display its properties, such as image, file etc.
@property (nonatomic, strong) SHKItem *item;

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

- (UIImage *)imageForThumbnail {
    
    return self.item.image;
}

- (NSString *)extensionForThumbnail {
    
    return [self.item.file.filename pathExtension];
}

- (SHKShareType)shareType {
    
    return self.item.shareType;
}

@end
