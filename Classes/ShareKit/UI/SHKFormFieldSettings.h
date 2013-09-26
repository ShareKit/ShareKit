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

#import <Foundation/Foundation.h>

typedef enum 
{
	SHKFormFieldTypeText,
	SHKFormFieldTypeTextNoCorrect,
    SHKFormFieldTypeTextLarge,
	SHKFormFieldTypePassword,
	SHKFormFieldTypeSwitch,
	SHKFormFieldTypeOptionPicker
} SHKFormFieldType;

#define SHKFormFieldSwitchOff @"0"
#define SHKFormFieldSwitchOn @"1"

@class SHKFormFieldOptionPickerSettings;

@interface SHKFormFieldSettings : NSObject 

@property (nonatomic, strong) NSString *label;
@property (nonatomic, strong) NSString *key;
@property SHKFormFieldType type;
@property (nonatomic, strong) NSString *start;

///Tells SHKFormController, if should be selected when the form is presented. In case multiple fields have this set to YES, only the first one is selected.
@property (nonatomic) BOOL select;

///It is a start value until user sets something. This holds actual value of a setting - this value is used when submitting the form, see valueToSave.
@property (nonatomic, strong) NSString *displayValue;

- (id)initWithLabel:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s;

+ (SHKFormFieldSettings *)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s;

///Value, which is saved to item, and will be used in share request. Mostly this value is user friendly, thus it just echoes displayValue.
- (NSString *)valueToSave;

///Form controller checks this. If it finds any field invalid, send button is disabled
- (BOOL)isValid;

@end
