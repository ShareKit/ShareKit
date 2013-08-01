//
//  SHKFormFieldLargeTextSettings.h
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
//
//

#import "SHKFormFieldSettings.h"

@interface SHKFormFieldLargeTextSettings : SHKFormFieldSettings

@property NSUInteger maxTextLength;
@property (nonatomic, strong) UIImage *image; //if image is being shared, it will be displayed
@property NSUInteger imageTextLength; //set only if image subtracts from text length (e.g. Twitter)
@property BOOL hasLink; //only if the link is not part of the text in a text view
@property BOOL allowSendingEmptyMessage;

+ (SHKFormFieldLargeTextSettings *)label:(NSString *)l
                                     key:(NSString *)k
                                    type:(SHKFormFieldType)t
                                   start:(NSString *)s
                           maxTextLength:(NSUInteger)maxTextLength
                                   image:(UIImage *)image
                         imageTextLength:(NSUInteger)imageTextLength
                                 hasLink:(BOOL)hasLink
                          allowEmptySend:(BOOL)allowEmpty
                                  select:(BOOL)select;

@end
