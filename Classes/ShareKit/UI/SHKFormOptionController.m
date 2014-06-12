//
//  SHKFormOptionController.m
//  PhotoToaster
//
//  Created by Steve Troppoli on 9/2/11.
//  Copyright 2011 East Coast Pixels. All rights reserved.
//

#import "SHKFormOptionController.h"
#import "SHKFormFieldSettings.h"
#import "SHKFormFieldOptionPickerSettings.h"
#import "SHKActivityIndicator.h"
#import "SHK.h"

@interface SHKFormOptionController()

@property (nonatomic, strong) SHKFormFieldOptionPickerSettings *settings;
@property (nonatomic, weak) id <SHKFormOptionControllerClient> client;
@property (nonatomic, weak) id <SHKFormOptionControllerOptionProvider> provider;

@property BOOL didLoad;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end

@implementation SHKFormOptionController

#pragma mark -
#pragma mark Initialization

- (id)initWithOptionPickerSettings:(SHKFormFieldOptionPickerSettings *)settingsItem client:(id <SHKFormOptionControllerClient>)optionClient;
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _settings = settingsItem;
		self.title = settingsItem.pickerTitle;
		_client = optionClient;
        _provider = settingsItem.provider;
    }
    return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
	[self updateFromOptions];
    
    BOOL isFirstOnNavigationController = [[self.navigationController viewControllers] indexOfObject:self] == 1; //so that if we navigate (pushNewContentOnSelection = YES) there is proper back button
    
    if (isFirstOnNavigationController) {
        
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                target:self
                                                                                                action:@selector(cancel:)] animated:YES];
    }
}

- (void)optionsEnumeratedDisplay:(NSArray *)displayOptions save:(NSArray *)saveOptions
{
	self.didLoad = true;
    
    if (saveOptions) {
        NSAssert([saveOptions count] == [displayOptions count], @"saveValues and displayValues mapping must match");
    }
    
	self.settings.displayValues = displayOptions;
    self.settings.saveValues = saveOptions;
    
	//defense - if there is any selected index out of bounds, remove it.
    [self.settings.selectedIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        if (index >= [displayOptions count]) {
            [self.settings.selectedIndexes removeIndex:index];
        }
    }];

	[self updateFromOptions];

	if (self.settings.allowMultiple || self.settings.pushNewContentOnSelection) {
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
                                message:[NSString stringWithFormat:@"%@ %@", SHKLocalizedString(@"Could not find any"), self.title]
                               delegate:self
                      cancelButtonTitle:SHKLocalizedString(@"Cancel")
                      otherButtonTitles:nil] show];
}

- (IBAction)cancel:(id)sender {

	if (self.provider != nil) {
		[self.provider SHKFormOptionControllerCancelEnumerateOptions:self];
	}
	[self.client SHKFormOptionControllerDidFinish:self];
}

- (IBAction)done:(id)sender {
	
    if (self.provider != nil) {
    	[self.provider SHKFormOptionControllerCancelEnumerateOptions:self];
    }	
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
    return [self.settings.displayValues count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	BOOL isSelected = [self.settings.selectedIndexes containsIndex:indexPath.row];
	cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
	cell.textLabel.text = self.settings.displayValues[indexPath.row];

    return cell;
}

- (void)updateFromOptions {
    
	NSAssert((!self.settings.fetchFromWeb && [self.settings.displayValues count] > 0 ) ||
             (self.settings.fetchFromWeb && (!self.didLoad || self.settings.pushNewContentOnSelection || [self.settings.displayValues count] > 0 )), @"ShareKit: there must be some choices or it must be fetchable");
	NSAssert(!self.settings.fetchFromWeb || self.provider, @"ShareKit: if you are fetching you must give a provider");
	
	if (self.settings.fetchFromWeb && !self.didLoad) {
        
		[self.provider SHKFormOptionControllerEnumerateOptions:self];
	}
    
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	if (self.settings.allowMultiple) {
        
        if ([self.settings.selectedIndexes containsIndex:indexPath.row]) {
            [self.settings.selectedIndexes removeIndex:indexPath.row];
        } else {
            [self.settings.selectedIndexes addIndex:indexPath.row];
        }
        
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    } else if (self.settings.pushNewContentOnSelection) {
        
        [self.settings.selectedIndexes removeAllIndexes];
        [self.settings.selectedIndexes addIndex:indexPath.row];
        
        //create new option controller
        SHKFormFieldOptionPickerSettings *newSettings = [self.settings copy];
        newSettings.displayValues = nil;
        newSettings.saveValues = nil;
        newSettings.pickerTitle = self.settings.displayValues[indexPath.row];
        [newSettings.selectedIndexes removeAllIndexes];
        
        SHKFormOptionController *newOptionController = [[SHKFormOptionController alloc] initWithOptionPickerSettings:newSettings client:self.client];
        newOptionController.selectionValue = [self.settings valueToSave];
        [self.navigationController pushViewController:newOptionController animated:YES];
        
    } else {
        
        [self.settings.selectedIndexes removeAllIndexes];
        [self.settings.selectedIndexes addIndex:indexPath.row];
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
