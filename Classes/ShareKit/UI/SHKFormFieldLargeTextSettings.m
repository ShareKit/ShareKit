//
//  SHKFormFieldLargeTextSettings.m
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
//
//

#import "SHKFormFieldLargeTextSettings.h"

@implementation SHKFormFieldLargeTextSettings

+ (SHKFormFieldLargeTextSettings *)label:(NSString *)l
                                     key:(NSString *)k
                                    type:(SHKFormFieldType)t
                                   start:(NSString *)s
                           maxTextLength:(NSUInteger)maxTextLength
                                   image:(UIImage *)image
                         imageTextLength:(NSUInteger)imageTextLength
                                    link:(NSURL *)url
                                    file:(SHKFile *)file
                          allowEmptySend:(BOOL)allowEmpty
                                  select:(BOOL)select {

    SHKFormFieldLargeTextSettings *result = [[SHKFormFieldLargeTextSettings alloc] initWithLabel:l key:k type:t start:s];
    result.maxTextLength = maxTextLength;
    result.image = image;
    result.imageTextLength = imageTextLength;
    result.url = url;
    result.file = file;
    result.allowSendingEmptyMessage = allowEmpty;
    result.select = select;
    
    return result;
}

- (NSUInteger)actualImageTextLength {
    
    NSUInteger result = (self.image && self.imageTextLength) ? self.imageTextLength : 0;
    return result;
}

- (BOOL)isValid {
    
    BOOL emptyCriterium = self.allowSendingEmptyMessage || [self.valueToSave length] > 0;
    BOOL maxTextLenCriterium = self.maxTextLength == 0 ? YES : [self.valueToSave length] <= self.maxTextLength - [self actualImageTextLength];
    
    if (emptyCriterium && maxTextLenCriterium) {
        return YES;
    } else {
        return NO;
    }
}

@end
