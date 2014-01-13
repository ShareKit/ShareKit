//
//  SHKFormFieldSettings.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/22/10.

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

/*!
 @class SHKFormFieldSettings
 @discussion Provides model layer for for SHKFormFieldCell.
 */

#import <Foundation/Foundation.h>

/*!
 @abstract Indicates what type of form cell should be created.
 @constant SHKFormFieldTypeText Cell with simple one line text field with text autocorrection. Best for user share content.
 @constant SHKFormFieldTypeTextNoCorrect Cell with simple one line text field with disabled text autocorrection. Useful for usernames or filenames.
 @constant SHKFormFieldTypePassword Cell with simple one line text field with hidden characters. Useful for passwords.
 @constant SHKFormFieldTypeTextLarge Cell similar to apple tweet sheet. Has multiple lines, attachment thumbnail and optionally character counter.
 @constant SHKFormFieldTypeSwitch Cell with switch. Useful for setting share options, such as private/public etc.
 @constant SHKFormFieldTypeOptionPicker Cell which presents multivalue picker on selection. Useful if user has to choose from multiple values with support for downloading the possible values asynchronously. Suitable e.g. for selecting what album shared photo goest to.
 */

typedef enum
{
	SHKFormFieldTypeText,
	SHKFormFieldTypeTextNoCorrect,
    SHKFormFieldTypeTextLarge,
	SHKFormFieldTypePassword,
	SHKFormFieldTypeSwitch,
	SHKFormFieldTypeOptionPicker
} SHKFormFieldType;

/*!
 @typedef SHKFormFieldValidationBlock
 @abstract Validation code for particular form field.
 @param formFieldSettings The SHKFormFieldSettings instance which is being evaluated.
 @result Returns YES if user's input is valid, NO if input is invalid.
 @discussion Validation is evaluated whenever user types a character. The input to be validated you get from valueToSave method, but other properties might be helpful too, such as maxTextLength. 
 */
typedef BOOL (^SHKFormFieldValidationBlock) (id formFieldSettings);

#define SHKFormFieldSwitchOff @"0"
#define SHKFormFieldSwitchOn @"1"

@class SHKFormFieldOptionPickerSettings;

@interface SHKFormFieldSettings : NSObject 

/// Displayed on the left of the cell with bold
@property (nonatomic, readonly, strong) NSString *label;

/// What SHKItem property this cell item will be saved.
@property (nonatomic, readonly, strong) NSString *key;

/// Specifies the type of cell to be constructed
@property SHKFormFieldType type;

/// Initial value of the cell
@property (nonatomic, readonly, strong) NSString *start;

/// Validation block for cell. It is evaluated on each user's character input. The default implementation always returns YES.
@property (nonatomic, copy) SHKFormFieldValidationBlock validationBlock;

///Tells SHKFormController, if should be selected when the form is presented. In case multiple fields have this set to YES, only the first one is selected.
@property (nonatomic) BOOL select;

///It is a start value until user sets something. This holds actual value of a setting - this value is used when submitting the form, @see valueToSave.
@property (nonatomic, strong) NSString *displayValue;

- (id)initWithLabel:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s;

+ (SHKFormFieldSettings *)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s;

///Value, which is saved to item, and will be used in share request. Mostly this value is user friendly, thus it just echoes displayValue.
- (NSString *)valueToSave;

///Form controller checks this. If it finds any field invalid, send button is disabled
- (BOOL)isValid;

@end
