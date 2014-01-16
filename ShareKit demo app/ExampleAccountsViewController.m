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
#import "SHKiOSSharer.h"
#import "SHKiOSTwitter.h"
#import "Debug.h"


@interface ExampleAccountsViewController ()

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray *sharers;

@end

@implementation ExampleAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        //makes checkmark appear after successful authentication
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadTable:)
                                                     name:@"SHKAuthDidFinish"
                                                   object:nil];
        
        //makes username appear after SHKShareTypeGetUserInfo fetches user data
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadTable:)
                                                     name:@"SHKSendDidFinish"
                                                   object:nil];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSDictionary *sharersDictionary = [SHK sharersDictionary];
    NSArray *services = [sharersDictionary objectForKey:@"services"];
    NSMutableArray *canShareServices = [[NSMutableArray alloc] initWithCapacity:[services count]];
    for (NSString *sharer in services) {
        Class sharerClass = NSClassFromString(sharer);
        if ([sharerClass canShare] && [sharerClass requiresAuthentication]) {
            [canShareServices addObject:sharer];
        }
    }
    self.sharers = canShareServices;  
    
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSString *sharerId = [self.sharers objectAtIndex:indexPath.row];
    Class sharerClass = NSClassFromString(sharerId);
    cell.textLabel.text = sharerId;
    
    if ([sharerClass isServiceAuthorized]) {
        
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.detailTextLabel.text = [sharerClass username];
    
    } else {
        
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [sharerClass username]; //should be nil, but this might better show possible error in logoff methods
    }
    
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sharerId = [self.sharers objectAtIndex:indexPath.row];
    Class sharerClass = NSClassFromString(sharerId);
    
    BOOL isiOSSharer = [sharerClass isSubclassOfClass:[SHKiOSSharer class]];
    
    if ([sharerClass isServiceAuthorized]) {
        
        if (isiOSSharer) {
            
            [sharerClass getUserInfo];
            /*
            UIAlertView *iosSharerAlert = [[UIAlertView alloc] initWithTitle:@"iOS Social.framework sharer"
                                                                     message:@"You can deauthorize this kind of sharer in settings.app, not here. By tapping this button you have refetched user info data only."
                                                                    delegate:nil
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:@"OK", nil];
            [iosSharerAlert show];*/
            
        } else {
            
            [sharerClass logout];
            [self.tableView reloadData];
        }
        
    } else {
        
        SHKSharer *sharer = [[sharerClass alloc] init];
        [sharer authorize];
        
        if (isiOSSharer) {
            /*UIAlertView *iosSharerAlert = [[UIAlertView alloc] initWithTitle:@"iOS Social.framework sharer"
                                                                     message:@"You can authorize this kind of sharer in settings.app, not here."
                                                                    delegate:nil
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:@"OK", nil];
            [iosSharerAlert show];*/
        }
    }
}

- (void)reloadTable:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self.tableView reloadData];
        SHKLog(@"table reloaded");
    });
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
