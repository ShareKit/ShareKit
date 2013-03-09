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
#import "SHKFormController.h"
#import "SHKCustomFormFieldCell.h"
#import "SHKFormFieldCellText.h"
#import "SHKFormFieldCellSwitch.h"
#import "SHKFormFieldCellOptionPicker.h"

#define CELL_IDENTIFIER_TEXT @"textCell"
#define CELL_IDENTIFIER_SWITCH @"switchCell"
#define CELL_IDENTIFIER_OPTIONS @"optionsCell"

@interface SHKFormController ()

@property (nonatomic, retain) UITextField *activeField;

@end

@implementation SHKFormController

@synthesize delegate, validateSelector, saveSelector, cancelSelector; 
@synthesize sections;
@synthesize activeField;
@synthesize autoSelect;

- (void)dealloc 
{
	delegate = nil;
	[sections release];
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
}

#pragma mark -

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (autoSelect)
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	if (SHKCONFIG(formBackgroundColor) != nil)
	{
		self.tableView.backgroundView = nil;
		self.tableView.backgroundColor = SHKCONFIG(formBackgroundColor);
	}
}


#pragma mark -
#pragma mark Table view
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
    UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[SHKFormFieldCellOptionPicker class]]) {
        
        SHKFormFieldSettings* settingsForCell = [self rowSettingsForIndexPath:indexPath];        
        SHKFormOptionController* optionsPicker = [[SHKFormOptionController alloc] initWithOptionsInfo:settingsForCell client:self];
		[self.navigationController pushViewController:optionsPicker animated:YES];
        [optionsPicker release];
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
    
    NSString *cellIdentifier = nil;
    Class cellSubclass = nil;
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    
    switch (settingsForCell.type) {
        case SHKFormFieldTypeText:
        case SHKFormFieldTypeTextNoCorrect:
        case SHKFormFieldTypePassword:
            cellIdentifier = CELL_IDENTIFIER_TEXT;
            cellSubclass = [SHKFormFieldCellText class];
            break;
        case SHKFormFieldTypeSwitch:
            cellIdentifier = CELL_IDENTIFIER_SWITCH;
            cellSubclass = [SHKFormFieldCellSwitch class];
            break;
        case SHKFormFieldTypeOptionPicker:
            cellIdentifier = CELL_IDENTIFIER_OPTIONS;
            cellStyle = UITableViewCellStyleValue1;
            cellSubclass = [SHKFormFieldCellOptionPicker class];
        default:
            break;
    }    
	
    SHKFormFieldCell* cell = (SHKFormFieldCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
		
        cell = [[[cellSubclass alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier] autorelease];
		cell.delegate = self;
        [cell setupLayout];
    }
		
	[cell setupWithSettings:settingsForCell];
	
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

#pragma mark - SHKFormFieldCellDelegate

- (void)setActiveTextField:(UITextField *)activeTextField {
    
    self.activeField = activeTextField;
}

#pragma mark - SHKFormOptionControllerClient

- (void)SHKFormOptionControllerDidFinish:(SHKFormOptionController *)optionController
{	
    NSArray *fields = [[sections objectAtIndex:0] objectForKey:@"rows"];
    NSUInteger index = [fields indexOfObject:optionController.settings];
    SHKCustomFormFieldCell* cell = (SHKCustomFormFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    [cell setupWithSettings:optionController.settings];        
    
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
	
    [self.activeField.delegate textFieldShouldReturn:self.activeField];
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
	return [self formValuesForSection:0];	// if this supports more than one section, option picking would have to be fixed, see SHKFormOptionControllerDidFinish
}
			
- (NSMutableDictionary *)formValuesForSection:(int)section
{
	// go through all form fields and get values
	NSMutableDictionary *formValues = [NSMutableDictionary dictionaryWithCapacity:0];	
	NSArray *allFieldSettings = [[sections objectAtIndex:section] objectForKey:@"rows"];
	
    for(SHKFormFieldSettings *settings in allFieldSettings)
	{		
        NSString *valueToSave = [settings valueToSave];
        if (valueToSave) {
            [formValues setObject:valueToSave forKey:settings.key];
        }        		
    }
		
	return formValues;	
}

@end

