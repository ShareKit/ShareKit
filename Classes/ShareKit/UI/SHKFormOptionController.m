//
//  SHKFormOptionController.m
//  PhotoToaster
//
//  Created by Steve Troppoli on 9/2/11.
//  Copyright 2011 East Coast Pixels. All rights reserved.
//

#import "SHKFormOptionController.h"
#import "SHKFormFieldSettings.h"
#import "SHKActivityIndicator.h"
#import "SHK.h"

@interface SHKFormOptionController()

@property BOOL didLoad;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (void) updateFromOptions;

@end

@implementation SHKFormOptionController

#pragma mark -
#pragma mark Initialization

- (id)initWithOptionsInfo:(SHKFormFieldSettings*) settingsItem client:(id<SHKFormOptionControllerClient>) optionClient
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.settings = settingsItem;
		self.title = [self.settings.optionPickerInfo objectForKey:@"title"];
		self.client = optionClient;
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	[self updateFromOptions];
	[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							 target:self
																							 action:@selector(cancel:)] animated:YES];
}

- (void) optionsEnumerated:(NSArray*) options;
{
	bool allowMultiple = [self.settings.optionPickerInfo objectForKey:@"allowMultiple"] != nil && [[self.settings.optionPickerInfo objectForKey:@"allowMultiple"] boolValue] == YES;
	self.didLoad = true;
	[self.settings.optionPickerInfo setValue:options forKey:@"itemsList"];
	// best reset the selection if values are not in range.
	NSString* curIndexs = [self.settings.optionPickerInfo objectForKey:@"curIndexes"];
	if(![curIndexs isEqualToString:@"-1"]){
		NSArray* indexes = [curIndexs componentsSeparatedByString:@","];
		for (NSString* index in indexes) {
			int indexVal = [index intValue];
			if(indexVal >= [options count]){
				[self.settings.optionPickerInfo setValue:[[NSNumber numberWithInt:-1]stringValue] forKey:@"curIndexes"];
				break;
			}
		}
	}

	[self updateFromOptions];

	if (allowMultiple) {
		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																								 target:self
																								 action:@selector(done:)] animated:YES];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self cancel:nil];
}

- (void) optionsEnumerationFailedWithError:(NSError *)error
{
	[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"No Options")
								 message:[NSString stringWithFormat:@"%@ %@", SHKLocalizedString(@"Could not find any"), [self.settings.optionPickerInfo objectForKey:@"title"]]
								delegate:self
					   cancelButtonTitle:SHKLocalizedString(@"Cancel")
					   otherButtonTitles:nil] show];}

- (IBAction)cancel:(id)sender {
	[[SHKActivityIndicator currentIndicator] hide];		
	if (self.provider != nil) {
		[self.provider SHKFormOptionControllerCancelEnumerateOptions:self];
	}
	[self.client SHKFormOptionControllerDidFinish:self];
}

- (IBAction)done:(id)sender {
	
    NSString *pickedValues = [self.settings optionPickerDisplayValueForIndexes:[self.settings.optionPickerInfo objectForKey:@"curIndexes"]];
    
    BOOL pickedNone = [pickedValues isEqualToString:@"-1"];    
    if(pickedNone) {        
        pickedValues = nil;        
    }
    
    self.settings.displayValue = pickedValues;
    [self.client SHKFormOptionControllerDidFinish:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[self.settings.optionPickerInfo objectForKey:@"itemsList"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	bool isSelected = false;
	NSString* curIndexs = [self.settings.optionPickerInfo objectForKey:@"curIndexes"];
	if(![curIndexs isEqualToString:@"-1"]){
		NSArray* indexes = [curIndexs componentsSeparatedByString:@","];
		isSelected = [indexes containsObject:[[NSNumber numberWithInt:indexPath.row]stringValue]];
	}

	cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	
	cell.textLabel.text = [[self.settings.optionPickerInfo objectForKey:@"itemsList"] objectAtIndex:indexPath.row] ;

    return cell;
}

- (void) updateFromOptions{
	NSAssert([self.settings.optionPickerInfo objectForKey:@"curIndexes"] != nil, @"ShareKit: missing the cur selection value");
	NSAssert([self.settings.optionPickerInfo objectForKey:@"itemsList"] != nil, @"ShareKit: missing the itemsList");
	NSAssert([self.settings.optionPickerInfo objectForKey:@"static"] != nil, @"ShareKit: missing the static flag");
	
	NSAssert(	([[self.settings.optionPickerInfo objectForKey:@"static"] boolValue] == true && [[self. settings.optionPickerInfo objectForKey:@"itemsList"] count] != 0 ) ||
				([[self.settings.optionPickerInfo objectForKey:@"static"] boolValue] == false && (!self.didLoad || [[self.settings.optionPickerInfo objectForKey:@"itemsList"] count] != 0 )), @"ShareKit: there must be some choices or it must be not static");
	NSAssert([[self.settings.optionPickerInfo objectForKey:@"static"] boolValue] == true || [self.settings.optionPickerInfo objectForKey:@"SHKFormOptionControllerOptionProvider"] != nil, @"ShareKit: if you are not static you must give a provider");
	
	if(![[self.settings.optionPickerInfo objectForKey:@"static"] boolValue] && self.provider == nil && !self.didLoad){// provider is a sentinal for a pending operation
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Loading...")];
		self.provider = [self.settings.optionPickerInfo objectForKey:@"SHKFormOptionControllerOptionProvider"];
		[self.provider SHKFormOptionControllerEnumerateOptions:self];
	}else{
		[[SHKActivityIndicator currentIndicator] hide];	
	}

	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	bool allowMultiple = [self.settings.optionPickerInfo objectForKey:@"allowMultiple"] != nil && [[self.settings.optionPickerInfo objectForKey:@"allowMultiple"] boolValue] == YES;
	if(allowMultiple){
		NSString* curIndexs = [self.settings.optionPickerInfo objectForKey:@"curIndexes"];
		if ([curIndexs isEqualToString:@"-1"]) {	// no prev selecion
			[self.settings.optionPickerInfo setValue:[[NSNumber numberWithInt:indexPath.row]stringValue] forKey:@"curIndexes"];
		}else{
			NSArray* indexes = [curIndexs componentsSeparatedByString:@","];
			NSUInteger loc = [indexes indexOfObject:[[NSNumber numberWithInt:indexPath.row]stringValue]];
			if (loc == NSNotFound) {	// append
				[self.settings.optionPickerInfo setValue:[NSString stringWithFormat:@"%@,%@", curIndexs, [[NSNumber numberWithInt:indexPath.row]stringValue]] forKey:@"curIndexes"];
			}else {						// remove
				NSMutableArray* tmpA = [NSMutableArray arrayWithArray:indexes];
				[tmpA removeObjectAtIndex:loc];
				NSString * result = [tmpA count] > 0 ? [[tmpA valueForKey:@"description"] componentsJoinedByString:@","] : @"-1";
				[self.settings.optionPickerInfo setValue:result
											 forKey:@"curIndexes"];
			}

		}
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}else{
		[self.settings.optionPickerInfo setValue:[[NSNumber numberWithInt:indexPath.row]stringValue] forKey:@"curIndexes"];
		[self done:nil];
	}
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

@end