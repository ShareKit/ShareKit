//
//  SHKFormFieldLargeTextSettings.h
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
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


#import "SHKFormFieldSettings.h"
@class SHKFile;

@interface SHKFormFieldLargeTextSettings : SHKFormFieldSettings

@property NSUInteger maxTextLength;
@property (nonatomic, strong) UIImage *image; //if image is being shared, it will be displayed
@property NSUInteger imageTextLength; //set only if image subtracts from text length (e.g. Twitter)
@property (nonatomic, strong) NSURL *url; //only if the link is not part of the text in a text view
@property BOOL allowSendingEmptyMessage;
@property (nonatomic, strong) SHKFile *file;

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
                                  select:(BOOL)select;

/**
 * If there is an image AND imageTextLength set, this evaluates, how many characters are taken by image if included. Useful if sharer has limited text length allowed.
 * @author Vilem Kurz
 *
 * @return How many characters should be substracted from text length.
 */
- (NSUInteger)actualImageTextLength;

@end
