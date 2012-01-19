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
	SHKFormFieldTypePassword,
	SHKFormFieldTypeSwitch,
	SHKFormFieldTypeOptionPicker
} SHKFormFieldType;

#define SHKFormFieldSwitchOff @"0"
#define SHKFormFieldSwitchOn @"1"

@interface SHKFormFieldSettings : NSObject 
{
	NSString *label;
	NSString *key;
	SHKFormFieldType type;	
	NSString *start;
/*	optionPickerInfo contains the info needed to present the fact that there is a value that 
	can be picked from a list. The actual choices can be provided in the optionPickerInfo or
	the sharer can provide them when asked. The latter is for when the option is something that
	can't be known ahead of time, like the list of albums to place a photo in or a group that a
	user belongs to.
 
	The format of the data is:
		'title' => title to put at the top of the list
		'curIndexes' => NSString comma sep list of index into the items list or -1.
		'allowMultiple' => NSNumber boolVal if true then multiple options can be picked and a done button is added.
			the value is to a comma delimited string, see SHKFormOptionController:pickedOption:
		'itemsList' => NSArray of NSString
		'static' => NSNumber boolVal false if the choices must be loaded with a network operation
		if static is false then you must also include
		'SHKFormOptionControllerOptionProvider' => something that implements the SHKFormOptionControllerOptionProvider
	protocol.
 
 */	
	NSMutableDictionary* optionPickerInfo;
}

@property (nonatomic, retain) NSString *label;
@property (nonatomic, retain) NSString *key;
@property SHKFormFieldType type;
@property (nonatomic, retain) NSString *start;
@property (nonatomic, retain) NSMutableDictionary *optionPickerInfo;

+ (id)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s;
+ (id)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s optionPickerInfo:(NSMutableDictionary*) oi;
- (NSString*) optionPickerValueForIndexes:(NSString*)indexes;
@end
