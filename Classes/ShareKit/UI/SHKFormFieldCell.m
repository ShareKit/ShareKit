//
//  SHKFormFieldCell.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

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

#import "SHKConfiguration.h"
#import "SHKFormFieldCell.h"
#import "SHKCustomFormController.h"

@implementation SHKFormFieldCell

@synthesize settings;
@synthesize labelWidth;
@synthesize textField, toggle, tmpValue;
@synthesize form;

#define SHK_FORM_CELL_PAD_LEFT 24
#define SHK_FORM_CELL_PAD_RIGHT 10


- (void)dealloc
{
	[settings release];
	[textField release];	
	[toggle release];
	[tmpValue release];
	[super dealloc];
}

- (UITextField *)getTextField
{
	if (textField == nil)
	{
		self.textField = [[[UITextField alloc] initWithFrame:CGRectMake(0,0,0,25)]autorelease];
		textField.clearsOnBeginEditing = NO;
		textField.returnKeyType = UIReturnKeyDone;
		textField.font = [UIFont systemFontOfSize:17];
		textField.textColor = [UIColor darkGrayColor];
		textField.delegate = form;
		[self.contentView addSubview:textField];
				
		[self setValue:tmpValue];
	}
	return textField;
}

- (void)layoutSubviews 
{
	[super layoutSubviews];	
	
	bool removeTextField = true;
	bool removeSwitch = true;
	bool removeDetailLabel = true;
	bool removeLabel = true;
	
	if (settings.type == SHKFormFieldTypeText || settings.type == SHKFormFieldTypeTextNoCorrect || settings.type == SHKFormFieldTypePassword)
	{
		self.textField.secureTextEntry = settings.type == SHKFormFieldTypePassword;
		
		if(settings.type == SHKFormFieldTypePassword || settings.type == SHKFormFieldTypeTextNoCorrect){
			textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			textField.autocorrectionType = UITextAutocorrectionTypeNo;
		}
		
		textField.frame = CGRectMake(labelWidth + SHK_FORM_CELL_PAD_LEFT, 
									 2 + round(self.contentView.bounds.size.height/2 - textField.bounds.size.height/2),
									 self.contentView.bounds.size.width - SHK_FORM_CELL_PAD_RIGHT - SHK_FORM_CELL_PAD_LEFT - labelWidth,
									 textField.bounds.size.height);

		[self.contentView addSubview:textField];
		[self.contentView bringSubviewToFront:textField];

		removeTextField = false;
		removeLabel = SHKCONFIG(usePlaceholders);
		if(!removeLabel)
			[self.contentView addSubview:self.textLabel];
	}
	else if (settings.type == SHKFormFieldTypeSwitch)
	{
		if (toggle == nil)
		{
			self.toggle = [[[UISwitch alloc] initWithFrame:CGRectZero] autorelease];	
			[self.contentView addSubview:toggle];
			[self setValue:tmpValue];
		}
		
		toggle.frame = CGRectMake(self.contentView.bounds.size.width-toggle.bounds.size.width-SHK_FORM_CELL_PAD_RIGHT,
								  round(self.contentView.bounds.size.height/2-toggle.bounds.size.height/2),
								  toggle.bounds.size.width,
								  toggle.bounds.size.height);
		removeLabel = false;
		removeSwitch = false;

		[self.contentView addSubview:toggle];
		[self.contentView addSubview:self.textLabel];
	}
	else if (settings.type == SHKFormFieldTypeOptionPicker)
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.detailTextLabel.frame = CGRectMake(labelWidth + SHK_FORM_CELL_PAD_LEFT, 
									 2 + round(self.contentView.bounds.size.height/2 - self.detailTextLabel.bounds.size.height/2),
									 self.contentView.bounds.size.width - SHK_FORM_CELL_PAD_RIGHT - SHK_FORM_CELL_PAD_LEFT - labelWidth,
									 self.detailTextLabel.bounds.size.height);
		removeLabel = false;
		removeDetailLabel = false;

		[self.contentView addSubview:self.detailTextLabel];
		[self.contentView addSubview:self.textLabel];
	}
	
	if (removeTextField)
		[textField removeFromSuperview];
	
	if (removeSwitch)
		[toggle removeFromSuperview];

	if(removeDetailLabel)
		[self.detailTextLabel removeFromSuperview];

	if(removeLabel)
		[self.textLabel removeFromSuperview];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	// don't actually select the row
	//[super setSelected:selected animated:animated];
	
	if (selected)
		[textField becomeFirstResponder];
	
	else
		[textField resignFirstResponder];
}


#pragma mark -

- (void)setSettings:(SHKFormFieldSettings *)s
{
	[settings release];
	settings = [s retain];
	[self setNeedsLayout];	
}

- (void)setValue:(NSString *)value
{
	self.tmpValue = value; // used to hold onto the value in case the form field element is created after this is set
	
	switch (settings.type) 
	{
		case SHKFormFieldTypeSwitch:
			[toggle setOn:[value isEqualToString:SHKFormFieldSwitchOn] animated:NO];
			break;
			
		case SHKFormFieldTypeText:
		case SHKFormFieldTypeTextNoCorrect:
		case SHKFormFieldTypePassword:
			textField.text = value;
			break;
		case SHKFormFieldTypeOptionPicker:
			self.detailTextLabel.text = value;
			break;
	}
}

- (NSString *)getValue
{
	switch (settings.type) 
	{
		case SHKFormFieldTypeSwitch:
			return toggle.on ? SHKFormFieldSwitchOn : SHKFormFieldSwitchOff;
		case SHKFormFieldTypeOptionPicker:
			return self.detailTextLabel.text;
		default:
			break;
	}
	
	return textField.text;
}

@end
