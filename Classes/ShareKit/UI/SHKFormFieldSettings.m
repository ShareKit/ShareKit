//
//  SHKFormFieldSettings.m
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

#import "SHKFormFieldSettings.h"


@implementation SHKFormFieldSettings

@synthesize label, key, type, start, value, optionPickerInfo, optionDetailLabelDefault;

- (void)dealloc
{
	[label release];
	[key release];
	[start release];
    [value release];
    [optionPickerInfo release];
    [optionDetailLabelDefault release];
	
	[super dealloc];
}

+ (id)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s
{
	return [SHKFormFieldSettings label:l key:k type:t start:s optionPickerInfo:nil optionDetailLabelDefault:nil];
}

+ (id)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s optionPickerInfo:(NSMutableDictionary*) oi optionDetailLabelDefault:(NSString *)od
{
	SHKFormFieldSettings *settings = [[SHKFormFieldSettings alloc] init];
	settings.label = l;
	settings.key = k;
	settings.type = t;	
	settings.start = s;
    settings.value = s;
	settings.optionPickerInfo = oi;
    settings.optionDetailLabelDefault = od;
	return [settings autorelease];
}

- (NSString*) optionPickerValueForIndexes:(NSString*)indexes
{
	NSString* resultVal = nil;
	if(![indexes isEqualToString:@"-1"]){
		NSArray* curIndexes = [indexes componentsSeparatedByString:@","];
		NSArray* values = [self.optionPickerInfo objectForKey:@"itemsList"];
		for (NSString* index in curIndexes) {
			int indexVal = [index intValue];
			resultVal = resultVal == nil ?  [values objectAtIndex:indexVal] : [NSString stringWithFormat:@"%@,%@", resultVal,[values objectAtIndex:indexVal]];
		}
	}	
	return resultVal == nil ? @"-1" : resultVal;
}

@end
