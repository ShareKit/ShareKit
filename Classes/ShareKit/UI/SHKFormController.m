//
//  SHKFormController.m
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

#import "SHK.h"
#import "SHKConfiguration.h"
#import "SHKCustomFormController.h"
#import "SHKCustomFormFieldCell.h"


@implementation SHKFormController

@synthesize delegate, validateSelector, saveSelector, cancelSelector; 
@synthesize sections, values;
@synthesize labelWidth;
@synthesize activeField;
@synthesize autoSelect;


- (void)dealloc 
{
	delegate = nil;
	[sections release];
	[values release];
	[activeField release];
	
    [super dealloc];
}


#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style title:(NSString *)barTitle rightButtonTitle:(NSString *)rightButtonTitle
{
	if (self = [super initWithStyle:style])
	{
		self.title = barTitle;
		
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)] autorelease];
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:rightButtonTitle
																				  style:UIBarButtonItemStyleDone
																				 target:self
																				 action:@selector(validateForm)] autorelease];
		
		self.values = [NSMutableDictionary dictionaryWithCapacity:0];
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	}
	return self;
}

- (void)addSection:(NSArray *)fields header:(NSString *)header footer:(NSString *)footer
{
	if (sections == nil)
		self.sections = [NSMutableArray arrayWithCapacity:0];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
	[dict setObject:fields forKey:@"rows"];
	
	if (header)
		[dict setObject:header forKey:@"header"];
		
	if (footer)
		[dict setObject:footer forKey:@"footer"];
	
	
	[sections addObject:dict];
	
	if (!SHKCONFIG(usePlaceholders)) {
		// Find the max length of the labels so we can use this value to align the left side of all form fields
		// TODO - should probably save this per section for flexibility
		if (sections.count == 1)
		{
			CGFloat newWidth = 0;
			CGSize size;
			
			for (SHKFormFieldSettings *field in fields)
			{
				// only use text field rows
				if (field.type != SHKFormFieldTypeText && 
					field.type != SHKFormFieldTypeTextNoCorrect &&
					field.type != SHKFormFieldTypePassword)
					continue;
				
				size = [field.label sizeWithFont:[UIFont boldSystemFontOfSize:17]];
				if (size.width > newWidth)
					newWidth = size.width;
			}
			
			self.labelWidth = newWidth;
		}
	}
}

#pragma mark -

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (autoSelect)
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	// Remove the SHK view wrapper from the window (but only if the view doesn't have another modal over it)
	// this happens when we have an options picker.
	if (self.navigationController.topViewController == nil)
		[[SHK currentHelper] viewWasDismissed];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (SHKCONFIG(formBackgroundColor) != nil)
         self.tableView.backgroundColor = SHKCONFIG(formBackgroundColor);
}


#pragma mark -
#pragma mark Table view
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	SHKFormFieldSettings* settingsForCell = [self rowSettingsForIndexPath:indexPath];
	if(settingsForCell.type == SHKFormFieldTypeOptionPicker){
		SHKFormOptionController* optionsPicker = [[[SHKFormOptionController alloc] initWithOptionsInfo:settingsForCell client:self] autorelease];
		[self.navigationController pushViewController:optionsPicker animated:YES];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [[[sections objectAtIndex:section] objectForKey:@"rows"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	SHKFormFieldSettings* settingsForCell = [self rowSettingsForIndexPath:indexPath];
    NSString *CellIdentifier = settingsForCell.type == SHKFormFieldTypeOptionPicker ? @"OptionCell" : @"Cell";
	
    SHKCustomFormFieldCell* cell = (SHKCustomFormFieldCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
	{
		cell = [[[SHKCustomFormFieldCell alloc] initWithStyle:(SHKFormFieldTypeOptionPicker ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault) 
											  reuseIdentifier:CellIdentifier] autorelease];
		cell.form = self;
		
		if (SHKCONFIG(formFontColor) != nil)
			cell.textLabel.textColor = SHKCONFIG(formFontColor);
	}
	
	// Since we are reusing table cells, make sure to save any existing values before overwriting
	if (cell.settings.key != nil && [cell getValue])
		[values setObject:[cell getValue] forKey:cell.settings.key];
    
	cell.settings = settingsForCell;
	if(SHKCONFIG(usePlaceholders) && settingsForCell.type != SHKFormFieldTypeOptionPicker)
	{
		cell.textField.placeholder = cell.settings.label;
		if(cell.settings.type != SHKFormFieldTypeText &&
		   cell.settings.type != SHKFormFieldTypePassword &&
		   cell.settings.type != SHKFormFieldTypeTextNoCorrect)
		{
			cell.textLabel.text = cell.settings.label;
		}
	}else{
		cell.labelWidth = labelWidth;
		cell.textLabel.text = cell.settings.label;
	}
	
	NSString *value = [values objectForKey:cell.settings.key];
	if (value == nil && cell.settings.start != nil){
		if(settingsForCell.type == SHKFormFieldTypeOptionPicker){
			NSString* curIndexes = [settingsForCell.optionPickerInfo objectForKey:@"curIndexes"];
			if (![curIndexes isEqualToString:@"-1"]) {
				value = [settingsForCell  optionPickerValueForIndexes:curIndexes];
			}else{
				value = cell.settings.start;
			}
		}else{
			value = cell.settings.start;
		}
	}	
	[cell setValue:value];
	
    return cell;
}

- (SHKFormFieldSettings *)rowSettingsForIndexPath:(NSIndexPath *)indexPath
{
	return [[[sections objectAtIndex:indexPath.section] objectForKey:@"rows"] objectAtIndex:indexPath.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[sections objectAtIndex:section] objectForKey:@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return [[sections objectAtIndex:section] objectForKey:@"footer"];
}


#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self validateForm];	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.activeField = textField;
}


#pragma mark -
#pragma mark OptionPicking
-(void) SHKFormOptionController:(SHKFormOptionController*) optionController pickedOption:(NSString*)pickedOption
{
	if(pickedOption != nil){
		BOOL pickedNone = [pickedOption isEqualToString:@"-1"];
		if(pickedNone)
			[values removeObjectForKey:optionController.settings.key];
		else
			[values setObject:pickedOption forKey:optionController.settings.key];
		
		NSArray *fields = [[sections objectAtIndex:0] objectForKey:@"rows"];
		NSUInteger index = [fields indexOfObject:optionController.settings];
		SHKCustomFormFieldCell* cell = (SHKCustomFormFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
		if (cell != nil) {
			[cell setValue:pickedNone ? cell.settings.start : pickedOption];
		}
		[self.tableView reloadData];
	}
	[self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark Completion

- (void)close
{
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void)cancel
{
	[self close];
	[delegate performSelector:cancelSelector withObject:self];
}

- (void)validateForm
{
	[activeField resignFirstResponder];
	[delegate performSelector:validateSelector withObject:self];
}

- (void)saveForm
{
	[delegate performSelector:saveSelector withObject:self];
	[self close];
}

#pragma mark -

- (NSMutableDictionary *)formValues
{
	return [self formValuesForSection:0];	// if this supports more than one section, option picking would have to be fixed, see SHKFormOptionController:pickedOption
}
			
- (NSMutableDictionary *)formValuesForSection:(int)section
{
	// go through all form fields and get values
	NSMutableDictionary *formValues = [NSMutableDictionary dictionaryWithCapacity:0];
	
	SHKCustomFormFieldCell *cell;
	int row = 0;
	NSArray *fields = [[sections objectAtIndex:section] objectForKey:@"rows"];
	
	for(SHKFormFieldSettings *field in fields)
	{		
		cell = (SHKCustomFormFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
		
		// Use text field if visible first		
		if ([cell.settings.key isEqualToString:field.key] && [cell getValue] != nil){
			if (cell.settings.type == SHKFormFieldTypeOptionPicker) {	// for option pickers, the start val is likely a label that doesn't mean anything like, 'select album'
				NSString* curVal = [cell getValue];
				if (![curVal isEqualToString:cell.settings.start]) {
					[formValues setObject:curVal forKey:field.key];
				}
			}else{
				[formValues setObject:[cell getValue] forKey:field.key];
			}
			
		}
		
		// If field is not visible, use cached value
		else if ([values objectForKey:field.key] != nil)
			[formValues setObject:[values objectForKey:field.key] forKey:field.key];
			
		row++;
	}
	
	return formValues;	
}
		 
		 


@end

