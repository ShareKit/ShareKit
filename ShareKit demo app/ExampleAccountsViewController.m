//
//  ExampleAccountsViewController.m
//  ShareKit
//
//  Created by Chris White on 1/22/13.
//
//

#import "ExampleAccountsViewController.h"
#import "SHK.h"
#import "SHKSharer.h"

@interface ExampleAccountsViewController ()

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray *sharers;

@end

@implementation ExampleAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(authDidFinish:)
                                                     name:@"SHKAuthDidFinish"
                                                   object:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSDictionary *sharersDictionary = [SHK sharersDictionary];
    self.sharers = [sharersDictionary objectForKey:@"services"];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
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
    return [self.sharers count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *sharerId = [self.sharers objectAtIndex:indexPath.row];
    
    cell.textLabel.text = sharerId;
    
    if ([NSClassFromString(sharerId) isServiceAuthorized]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sharerId = [self.sharers objectAtIndex:indexPath.row];
    if (YES == [NSClassFromString(sharerId) isServiceAuthorized]) {
        [NSClassFromString(sharerId) logout];
        [self.tableView reloadData];
    } else {
        SHKSharer *sharer = [[NSClassFromString(sharerId) alloc] init];
        [sharer authorize];
    }
}

- (void)authDidFinish:(NSNotification*)notification
{    
    [self.tableView reloadData];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
