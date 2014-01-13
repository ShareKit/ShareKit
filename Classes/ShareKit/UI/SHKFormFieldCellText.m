//
//  SHKFormFieldCellText.m
//  ShareKit
//
//  Created by Vilem Kurz on 30/05/2012.
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

#import "SHKFormFieldCellText.h"
#import "SHKConfiguration.h"
#import "SHKFormFieldSettings.h"

#define SHK_FORM_CELL_TEXTFIELD_HEIGHT 25

@implementation SHKFormFieldCellText

@synthesize textField;


- (void)setupLayout {
    
    CGRect frame = CGRectMake(SHK_FORM_CELL_PAD_LEFT, 
                              2 + round(self.contentView.bounds.size.height/2 - SHK_FORM_CELL_TEXTFIELD_HEIGHT/2),
                              self.contentView.bounds.size.width - SHK_FORM_CELL_PAD_RIGHT - SHK_FORM_CELL_PAD_LEFT,
                              SHK_FORM_CELL_TEXTFIELD_HEIGHT);
    
    UITextField *aTextField = [[UITextField alloc] initWithFrame:frame];
    self.textField = aTextField;
    
    self.textField.clearsOnBeginEditing = NO;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.font = [UIFont systemFontOfSize:17];
    self.textField.textColor = [UIColor darkGrayColor];
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.textField.delegate = self;
    [self.contentView addSubview:self.textField];
    
    [super setupLayout];
}

- (void)setupWithSettings:(SHKFormFieldSettings *)settings {
    
    self.textField.text = settings.displayValue;
    self.textField.placeholder = settings.label;
    
    if (settings.type == SHKFormFieldTypePassword) {
        self.textField.secureTextEntry = YES;
    }
		
    if (settings.type == SHKFormFieldTypePassword || settings.type == SHKFormFieldTypeTextNoCorrect) {
			self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }
    
    [super setupWithSettings:settings];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    if (selected) {
        [self.textField becomeFirstResponder];
    } else {
        [self userSetValue:self.textField.text];
        [self.textField resignFirstResponder];
    }        
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    [self userSetValue:self.textField.text];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
	[self userSetValue:self.textField.text];
    [self.delegate setActiveTextField:nil];
    [self.textField resignFirstResponder];	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	[self.delegate setActiveTextField:self.textField];
}

- (void)userSetValue:(NSString *)newValue {
    
    if ([newValue isEqualToString:@""]) {
        newValue = nil;
    }
    [super userSetValue:newValue];
}

@end
