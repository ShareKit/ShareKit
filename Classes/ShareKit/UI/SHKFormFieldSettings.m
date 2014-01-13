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
#import "SHKFormFieldOptionPickerSettings.h"

@implementation SHKFormFieldSettings

+ (SHKFormFieldSettings *)label:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s
{
	SHKFormFieldSettings *result = [[SHKFormFieldSettings alloc] initWithLabel:l key:k type:t start:s];
    return result;
}

- (id)initWithLabel:(NSString *)l key:(NSString *)k type:(SHKFormFieldType)t start:(NSString *)s {
    
    self = [super init];
    if (self) {
        _label = l;
        _key = k;
        _type = t;
        _start = s;
        _displayValue = s;
        _select = NO;
        _validationBlock = ^ (id formFieldSettings) { return YES; };
    }
    return self;
}

- (NSString *)valueToSave {
    
    NSString *result = self.displayValue;
    return result;
}

- (BOOL)isValid {
    
    __weak typeof(self) weakSelf = self;
    return  self.validationBlock (weakSelf);
}

@end
