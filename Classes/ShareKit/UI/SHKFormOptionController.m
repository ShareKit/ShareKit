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

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
- (void) updateFromOptions;

@end


@implementation SHKFormOptionController

@synthesize settings, client;

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
	[self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							 target:self
																							 action:@selector(cancel:)] autorelease] animated:YES];
}


- (void) optionsEnumerated:(NSArray*) options;
{
	bool allowMultiple = [self.settings.optionPickerInfo objectForKey:@"allowMultiple"] != nil && [[self.settings.optionPickerInfo objectForKey:@"allowMultiple"] boolValue] == YES;
	didLoad = true;
	provider = nil;
	[settings.optionPickerInfo setValue:options forKey:@"itemsList"];
	// best reset the selection if values are not in range.
	NSString* curIndexs = [settings.optionPickerInfo objectForKey:@"curIndexes"];
	if(![curIndexs isEqualToString:@"-1"]){
		NSArray* indexes = [curIndexs componentsSeparatedByString:@","];
		for (NSString* index in indexes) {
			int indexVal = [index intValue];
			if(indexVal >= [options count]){
				[settings.optionPickerInfo setValue:[[NSNumber numberWithInt:-1]stringValue] forKey:@"curIndexes"];
				break;
			}
		}
	}

	[self updateFromOptions];

	if (allowMultiple) {
		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																								 target:self
																								 action:@selector(done:)] autorelease] animated:YES];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self cancel:nil];
}

- (void) optionsEnumerationFailedWithError:(NSError *)error
{
	
	provider = nil;
	[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"No Options")
								 message:[NSString stringWithFormat:@"%@ %@", SHKLocalizedString(@"Could not find any"), [self.settings.optionPickerInfo objectForKey:@"title"]]
								delegate:self
					   cancelButtonTitle:SHKLocalizedString(@"Cancel")
					   otherButtonTitles:nil] autorelease] show];}

- (IBAction)cancel:(id)sender {
	[[SHKActivityIndicator currentIndicator] hide];		
	if (provider != nil) {
		[provider SHKFormOptionControllerCancelEnumerateOptions:self];
	}
	[client SHKFormOptionController:self pickedOption:nil];
}

- (IBAction)done:(id)sender {
	[client SHKFormOptionController:self pickedOption:[settings optionPickerValueForIndexes:[settings.optionPickerInfo objectForKey:@"curIndexes"]]];
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
    return [[settings.optionPickerInfo objectForKey:@"itemsList"] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	bool isSelected = false;
	NSString* curIndexs = [settings.optionPickerInfo objectForKey:@"curIndexes"];
	if(![curIndexs isEqualToString:@"-1"]){
		NSArray* indexes = [curIndexs componentsSeparatedByString:@","];
		isSelected = [indexes containsObject:[[NSNumber numberWithInt:indexPath.row]stringValue]];
	}

	cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	
	cell.textLabel.text = [[settings.optionPickerInfo objectForKey:@"itemsList"] objectAtIndex:indexPath.row] ;

    return cell;
}

- (void) updateFromOptions{
	NSAssert([settings.optionPickerInfo objectForKey:@"curIndexes"] != nil, @"ShareKit: missing the cur selection value");
	NSAssert([settings.optionPickerInfo objectForKey:@"itemsList"] != nil, @"ShareKit: missing the itemsList");
	NSAssert([settings.optionPickerInfo objectForKey:@"static"] != nil, @"ShareKit: missing the static flag");
	
	NSAssert(	([[settings.optionPickerInfo objectForKey:@"static"] boolValue] == true && [[settings.optionPickerInfo objectForKey:@"itemsList"] count] != 0 ) ||
				([[settings.optionPickerInfo objectForKey:@"static"] boolValue] == false && (!didLoad || [[settings.optionPickerInfo objectForKey:@"itemsList"] count] != 0 )), @"ShareKit: there must be some choices or it must be not static");
	NSAssert([[settings.optionPickerInfo objectForKey:@"static"] boolValue] == true || [settings.optionPickerInfo objectForKey:@"SHKFormOptionControllerOptionProvider"] != nil, @"ShareKit: if you are not static you must give a provider");
	
	if(![[settings.optionPickerInfo objectForKey:@"static"] boolValue] && provider == nil && !didLoad){// provider is a sentinal for a pending operation
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Loading...")];
		provider = [settings.optionPickerInfo objectForKey:@"SHKFormOptionControllerOptionProvider"];
		[provider SHKFormOptionControllerEnumerateOptions:self];
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
		NSString* curIndexs = [settings.optionPickerInfo objectForKey:@"curIndexes"];
		if ([curIndexs isEqualToString:@"-1"]) {	// no prev selecion
			[settings.optionPickerInfo setValue:[[NSNumber numberWithInt:indexPath.row]stringValue] forKey:@"curIndexes"];
		}else{
			NSArray* indexes = [curIndexs componentsSeparatedByString:@","];
			NSUInteger loc = [indexes indexOfObject:[[NSNumber numberWithInt:indexPath.row]stringValue]];
			if (loc == NSNotFound) {	// append
				[settings.optionPickerInfo setValue:[NSString stringWithFormat:@"%@,%@", curIndexs, [[NSNumber numberWithInt:indexPath.row]stringValue]] forKey:@"curIndexes"];
			}else {						// remove
				NSMutableArray* tmpA = [NSMutableArray arrayWithArray:indexes];
				[tmpA removeObjectAtIndex:loc];
				NSString * result = [tmpA count] > 0 ? [[tmpA valueForKey:@"description"] componentsJoinedByString:@","] : @"-1";
				[settings.optionPickerInfo setValue:result
											 forKey:@"curIndexes"];
			}

		}
		[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	}else{
		[settings.optionPickerInfo setValue:[[NSNumber numberWithInt:indexPath.row]stringValue] forKey:@"curIndexes"];
		[client SHKFormOptionController:self pickedOption:[[settings.optionPickerInfo objectForKey:@"itemsList"] objectAtIndex:indexPath.row]];
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


- (void)dealloc {
	[settings release];
    [super dealloc];
}


@end

