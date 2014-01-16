//
//  RootViewController.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import "RootViewController.h"
#import "ExampleShareLink.h"
#import "ExampleShareImage.h"
#import "ExampleShareText.h"
#import "ExampleShareFile.h"
#import "SHK.h"
#import "ExampleAccountsViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)loadView
{
	[super loadView];
	
	self.toolbarItems = [NSArray arrayWithObjects:
						 [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Accounts") style:UIBarButtonItemStyleBordered target:self action:@selector(showAccounts)],
                         /*
                         [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Facebook Connect") style:UIBarButtonItemStyleBordered target:self action:@selector(facebookConnect)],*/
						 nil
						 ];	
}

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(authDidFinish:)
                                                 name:@"SHKAuthDidFinish"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendDidCancel:)
                                                 name:@"SHKSendDidCancel"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendDidStart:)
                                                 name:@"SHKSendDidStartNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendDidFinish:)
                                                 name:@"SHKSendDidFinish"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendDidFailWithError:)
                                                 name:@"SHKSendDidFailWithError"
                                               object:nil];
}

#pragma mark -
#pragma mark Table view data source


// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 4;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	switch (indexPath.row) 
	{
		case 0:
			cell.textLabel.text = SHKLocalizedString(@"Sharing a Link");
			break;
			
		case 1:
			cell.textLabel.text = SHKLocalizedString(@"Sharing an Image");
			break;
			
		case 2:
			cell.textLabel.text = SHKLocalizedString(@"Sharing Text");
			break;
			
		case 3:
			cell.textLabel.text = SHKLocalizedString(@"Sharing a File");
			break;
	}

    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.row) 
	{
		case 0:
			[self.navigationController pushViewController:[[ExampleShareLink alloc] initWithNibName:nil bundle:nil] animated:YES];
			break;
			
		case 1:
			
			[self.navigationController pushViewController:[[ExampleShareImage alloc] initWithNibName:nil bundle:nil] animated:YES];
			break;
			
		case 2:
			[self.navigationController pushViewController:[[ExampleShareText alloc] initWithNibName:nil bundle:nil] animated:YES];
			break;
			
		case 3:
			[self.navigationController pushViewController:[[ExampleShareFile alloc] initWithNibName:nil bundle:nil] animated:YES];
			break;		
			
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)showAccounts
{
    ExampleAccountsViewController *accountsViewController = [[ExampleAccountsViewController alloc] init];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:accountsViewController];
    
    [self presentViewController:navigationController
                       animated:YES
                     completion:^{
                     }];
}

- (void)authDidFinish:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *success = [userInfo objectForKey:@"success"];
    
    if (NO == [success boolValue]) {
        NSLog(@"authDidFinish: NO");
    } else {
        NSLog(@"authDidFinish: YES");
    }
    
}

- (void)sendDidCancel:(NSNotification*)notification
{
    NSLog(@"sendDidCancel:");
}

- (void)sendDidStart:(NSNotification*)notification
{
    NSLog(@"sendDidStart:");
}

- (void)sendDidFinish:(NSNotification*)notification
{
    NSLog(@"sendDidFinish:");
}

- (void)sendDidFailWithError:(NSNotification*)notification
{
    NSLog(@"sendDidFailWithError:");
}

@end

