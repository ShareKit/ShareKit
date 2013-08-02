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

@interface SHKFormFieldOptionPickerSettings : SHKFormFieldSettings

/*	SHKFormFieldOptionPickerSettings contains the info needed to present the fact that there is a value that
 can be picked from a list. The actual choices can be provided here or
 the sharer can provide them when asked. The latter is for when the option is something that
 can't be known ahead of time, like the list of albums to place a photo in or a group that a
 user belongs to.
 */

@property (strong, nonatomic) NSString *pickerTitle; //title to put at the top of the list
@property (strong, nonatomic) NSMutableIndexSet *selectedIndexes; //these indexes will be preselected on load (former curIndexes) and changed as per user choice. Save value will be calculated using this. Can be nil.
@property (strong, nonatomic) NSArray *displayValues; //This will be displayed to user. If you need different (non-readable) strings to save, map them in saveValues (former itemsList)
@property (strong, nonatomic) NSArray *saveValues; //if nil, displayValues are saved. (former itemsValues)
@property (nonatomic) BOOL allowMultiple; //if true then multiple options can be picked and a done button is added.
@property (nonatomic) BOOL fetchFromWeb; //if the choices must be loaded with a network operation. If true, provider is mandatory (former static)
@property (weak, nonatomic) id <SHKFormOptionControllerOptionProvider> provider;

+ (SHKFormFieldOptionPickerSettings *)label:(NSString *)l
                                        key:(NSString *)k
                                       type:(SHKFormFieldType)t
                                      start:(NSString *)s
                                pickerTitle:(NSString *)pickerTitle
                            selectedIndexes:(NSMutableIndexSet *)selectedIndexes
                              displayValues:(NSArray *)displayValues
                                 saveValues:(NSArray *)saveValues
                              allowMultiple:(BOOL)allowMultiple
                               fetchFromWeb:(BOOL)fetchFromWeb
                                   provider:(id <SHKFormOptionControllerOptionProvider>)provider;

@end
