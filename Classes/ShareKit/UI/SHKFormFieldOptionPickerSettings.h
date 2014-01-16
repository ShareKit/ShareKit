//
//  SHKFormOptionControllerSettings.h
//  ShareKit
//
//  Inspired by Steve Troppoli
//  Created by Vilém Kurz on 7/28/13.
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

#import <Foundation/Foundation.h>
#import "SHKFormFieldSettings.h"

#import "SHKFormOptionController.h"

/*!
 @class SHKFormFieldOptionPickerSettings
 @discussion SHKFormFieldOptionPickerSettings contains the info needed to present the value that
 can be picked from a list. The actual choices can be provided here or
 the sharer can provide them when asked. The latter is for when the option is something that
 can't be known ahead of time, like the list of albums to place a photo in or a group that a
 user belongs to.
 */

@interface SHKFormFieldOptionPickerSettings : SHKFormFieldSettings

/// Title to put at the top of the list
@property (strong, nonatomic) NSString *pickerTitle;

/// These indexes will be preselected on load (former curIndexes) and changed as per user choice. Save value will be calculated using this. Can be nil.
@property (strong, nonatomic) NSMutableIndexSet *selectedIndexes;

///This will be displayed to user. If you need different (non-readable) strings to save, map them in saveValues (former itemsList)
@property (strong, nonatomic) NSArray *displayValues;

///if nil, displayValues are saved. (former itemsValues)
@property (strong, nonatomic) NSArray *saveValues;

///if true then multiple options can be picked and a done button is added.
@property (nonatomic) BOOL allowMultiple;

///if the choices must be loaded with a network operation. If true, provider is mandatory (former static)
@property (nonatomic) BOOL fetchFromWeb;

@property (weak, nonatomic) id <SHKFormOptionControllerOptionProvider> provider;

///if there is a need to push new content controller. For example Dropbox sharer needs to traverse files. Done button is added.
@property (nonatomic) BOOL pushNewContentOnSelection;

/*!
 @param label Presented bold on the left side
 @param key  Corresponding key in SHKItem
 @param type  Type of form field to be created
 @param start  Placeholder, or initial value
 @param pickerTitle Title to put at the top of the list
 @param selectedIndexes These indexes will be preselected on load (former curIndexes) and changed as per user choice. Save value will be calculated using this. Can be nil.
 @param displayValues This will be displayed to user. Can be nil, if you fetch from web. If you need different (non-readable) strings to save, map them in saveValues (former itemsList)
 @param saveValues If nil, displayValues are saved. (former itemsValues)
 @param allowMultiple If true then multiple options can be picked and a done button is added.
 @param fetchFromWeb If the choices must be loaded with a network operation. If true, provider is mandatory (former static)
 @param provider Provider delegate responsible for fetching options from network
 @result Instance of SHKFormFieldOptionPickerSettings
 */
+ (SHKFormFieldOptionPickerSettings *)label:(NSString *)l
                                        key:(NSString *)k
                                      start:(NSString *)s
                                pickerTitle:(NSString *)pickerTitle
                            selectedIndexes:(NSMutableIndexSet *)selectedIndexes
                              displayValues:(NSArray *)displayValues
                                 saveValues:(NSArray *)saveValues
                              allowMultiple:(BOOL)allowMultiple
                               fetchFromWeb:(BOOL)fetchFromWeb
                                   provider:(id <SHKFormOptionControllerOptionProvider>)provider;

@end
