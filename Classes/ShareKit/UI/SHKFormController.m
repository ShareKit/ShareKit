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

#import "SHKFormController.h"

#import "SHKConfiguration.h"
#import "SHKFormFieldCellText.h"
#import "SHKFormFieldCellTextLarge.h"
#import "SHKFormFieldCellSwitch.h"
#import "SHKFormFieldCellOptionPicker.h"
#import "SHKFormFieldSettings.h"
#import "SHKFormFieldLargeTextSettings.h"

#define CELL_IDENTIFIER_TEXT @"textCell"
#define CELL_IDENTIFIER_LARGE_TEXT @"largeTextCell"
#define CELL_IDENTIFIER_SWITCH @"switchCell"
#define CELL_IDENTIFIER_OPTIONS @"optionsCell"

#define LARGE_TEXT_CELL_HEIGHT 120

@interface SHKFormController ()

@property (nonatomic, strong) UITextField *activeField;

- (SHKFormFieldSettings *)rowSettingsForIndexPath:(NSIndexPath *)indexPath;

@end

@implementation SHKFormController

#pragma mark -
#pragma mark Initialization

- (id)initWithStyle:(UITableViewStyle)style title:(NSString *)barTitle rightButtonTitle:(NSString *)rightButtonTitle
{
	if (self = [super initWithStyle:style])
	{
		self.title = barTitle;
		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:rightButtonTitle
																				  style:UIBarButtonItemStyleDone
																				 target:self
																				 action:@selector(validateForm)];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	}
	return self;
}

- (void)addSection:(NSArray *)fields header:(NSString *)header footer:(NSString *)footer
{
	if (self.sections == nil)
		self.sections = [NSMutableArray arrayWithCapacity:0];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
	[dict setObject:fields forKey:@"rows"];
	
	if (header)
		[dict setObject:header forKey:@"header"];
		
	if (footer)
		[dict setObject:footer forKey:@"footer"];
	
	[self.sections addObject:dict];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if (self.autoSelect) {
		[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else {
        
        NSIndexPath *fieldToSelect = [self fieldToSelect];
        if (fieldToSelect) {
            [self.tableView selectRowAtIndexPath:fieldToSelect animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    [self checkFieldValidity];
}

- (NSIndexPath *)fieldToSelect {
    
    NSIndexPath *result = nil;
    NSArray *fieldToSelect = [self settingsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
    
        BOOL result = [(SHKFormFieldSettings *)obj select];
        if (result) stop = YES;
        return result;
    }];
    
    if ([fieldToSelect count]) result = fieldToSelect[0];
    return result;
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
#pragma mark Right Bar Button dynamic enable

- (void)checkFieldValidity {
       
    NSArray *invalidFields = [self settingsPassingTest:^BOOL (id obj, NSUInteger idx, BOOL *stop) {
        
        BOOL result = ![(SHKFormFieldSettings *)obj isValid];
        if (!result) stop = YES;
        return result;
    }];
    
    BOOL allowSend = [invalidFields count] == 0;    
    self.navigationItem.rightBarButtonItem.enabled = allowSend;
}

#pragma mark -
#pragma mark Table view

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
    UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell isKindOfClass:[SHKFormFieldCellOptionPicker class]]) {
        
        SHKFormFieldOptionPickerSettings *settingsForCell = (SHKFormFieldOptionPickerSettings *)[self rowSettingsForIndexPath:indexPath];
        SHKFormOptionController* optionsPicker = [[SHKFormOptionController alloc] initWithOptionPickerSettings:settingsForCell client:self];
		[self.navigationController pushViewController:optionsPicker animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SHKFormFieldSettings *settings = [self rowSettingsForIndexPath:indexPath];
    if (settings.type == SHKFormFieldTypeTextLarge) {
        return LARGE_TEXT_CELL_HEIGHT;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //to allow clip overlap neighbouring cell
    BOOL isLargeTextCell = [(SHKFormFieldCellTextLarge *)cell settings].type == SHKFormFieldTypeTextLarge;
    if (isLargeTextCell) {
        [self.tableView bringSubviewToFront:cell];
    }
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [[[self.sections objectAtIndex:section] objectForKey:@"rows"] count];
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
            cellSubclass = [self SHKFormFieldCellTextClass];
            break;
        case SHKFormFieldTypeTextLarge:
            cellIdentifier = CELL_IDENTIFIER_LARGE_TEXT;
            cellSubclass = [self SHKFormFieldCellTextLargeClass];
            break;
        case SHKFormFieldTypeSwitch:
            cellIdentifier = CELL_IDENTIFIER_SWITCH;
            cellSubclass = [self SHKFormFieldCellSwitchClass];
            break;
        case SHKFormFieldTypeOptionPicker:
            cellIdentifier = CELL_IDENTIFIER_OPTIONS;
            cellStyle = UITableViewCellStyleValue1;
            cellSubclass = [self SHKFormFieldCellOptionPickerClass];
        default:
            break;
    }    
	
    SHKFormFieldCell* cell = (SHKFormFieldCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
		
        cell = [[cellSubclass alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier];
		cell.delegate = self;
        [cell setupLayout];
    }
		
	[cell setupWithSettings:settingsForCell];
	
    return cell;
}

- (Class)SHKFormFieldCellTextClass { return [SHKFormFieldCellText class]; }

- (Class)SHKFormFieldCellTextLargeClass { return [SHKFormFieldCellTextLarge class]; }

- (Class)SHKFormFieldCellSwitchClass { return [SHKFormFieldCellSwitch class]; }

- (Class)SHKFormFieldCellOptionPickerClass { return [SHKFormFieldCellOptionPicker class]; }

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [[self.sections objectAtIndex:section] objectForKey:@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return [[self.sections objectAtIndex:section] objectForKey:@"footer"];
}

#pragma mark -

- (SHKFormFieldSettings *)rowSettingsForIndexPath:(NSIndexPath *)indexPath
{
	id result = [[[self.sections objectAtIndex:indexPath.section] objectForKey:@"rows"] objectAtIndex:indexPath.row];
    return result;
}

- (NSArray *)settingsPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate {
    
    NSMutableArray *result = [@[] mutableCopy];
    BOOL *shouldStop = NO;
    
    for (NSDictionary *section in self.sections) {
        
        if (shouldStop) break;
        
        NSArray *settingsForSection = [section objectForKey:@"rows"];
        
        for (SHKFormFieldSettings *settings in settingsForSection) {
            
            if (shouldStop) break;
            
            NSUInteger indexOfSettings = [settingsForSection indexOfObject:settings];
            BOOL passed = predicate(settings, indexOfSettings, shouldStop);
            if (passed) {
                
                NSInteger sectionIndex = [self.sections indexOfObject:section];
                [result addObject:[NSIndexPath indexPathForRow:indexOfSettings inSection:sectionIndex]];
            }
        }
    }
    return result;
}

#pragma mark - SHKFormFieldCellDelegate

- (void)setActiveTextField:(UITextField *)activeTextField {
    
    self.activeField = activeTextField;
}

- (void)valueChanged {
    
    [self checkFieldValidity];
}

#pragma mark - SHKFormOptionControllerClient

- (void)SHKFormOptionControllerDidFinish:(SHKFormOptionController *)optionController
{	
    [self.tableView reloadData];
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
    self.cancelBlock(self);
}

- (void)validateForm
{
    [self.activeField.delegate textFieldShouldReturn:self.activeField];
    self.validateBlock(self);
}

- (void)saveForm
{
    self.saveBlock(self);
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
	NSArray *allFieldSettings = [[self.sections objectAtIndex:section] objectForKey:@"rows"];
	
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

