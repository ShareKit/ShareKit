//
//  SHKFormFieldCellText.m
//  ShareKit
//
//  Created by Vilem Kurz on 30/05/2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "SHKFormFieldCellText.h"
#import "SHKConfiguration.h"

#define SHK_FORM_CELL_TEXTFIELD_HEIGHT 25

@implementation SHKFormFieldCellText

@synthesize textField;

- (void)dealloc {
    
    [textField release];
    [super dealloc];
}

- (void)setupLayout {
    
    CGRect frame = CGRectMake(SHK_FORM_CELL_PAD_LEFT, 
                              2 + round(self.contentView.bounds.size.height/2 - SHK_FORM_CELL_TEXTFIELD_HEIGHT/2),
                              self.contentView.bounds.size.width - SHK_FORM_CELL_PAD_RIGHT - SHK_FORM_CELL_PAD_LEFT,
                              SHK_FORM_CELL_TEXTFIELD_HEIGHT);
    
    UITextField *aTextField = [[UITextField alloc] initWithFrame:frame];
    self.textField = aTextField;
    [aTextField release];
    
    self.textField.clearsOnBeginEditing = NO;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.font = [UIFont systemFontOfSize:17];
    self.textField.textColor = [UIColor darkGrayColor];
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.textField.delegate = self;
    [self.contentView addSubview:self.textField];
    
    [super setupLayout];
}

- (void)setupWithSettings:(SHKFormFieldSettings *)settings {
    
    self.textField.text = settings.value;
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

@end
