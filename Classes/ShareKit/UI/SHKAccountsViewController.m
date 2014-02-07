//
//  ExampleAccountsViewController.m
//  ShareKit
//
//  Created by Chris White on 1/22/13.
//
//

#import "SHKAccountsViewController.h"
#import "SHK.h"
#import "SHKSharer.h"
#import "SHKiOSSharer.h"
#import "Debug.h"
#import "SHKConfiguration.h"


@interface SHKAccountsViewController ()

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSArray *sharers;

@end

@implementation SHKAccountsViewController

+ (instancetype)openFromViewController:(UIViewController *)rootViewController {
    
    id result = [[SHKCONFIG(SHKAccountsViewControllerSubclass) alloc] initWithSharers:[SHK activeSharersRequiringAuthentication]];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:result];
    [rootViewController presentViewController:navigationController animated:YES completion:nil];
    return result;
}

- (Class)accountsViewCellClass {
    
    return [UITableViewCell class];
}

- (instancetype)initWithSharers:(NSArray *)sharers
{
    self = [super init];
    if (self) {
        
        _sharers = sharers;
        
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

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
        cell = [[[self accountsViewCellClass] alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    Class sharerClass = [self.sharers objectAtIndex:indexPath.row];
    cell.textLabel.text = [sharerClass sharerTitle];
    
    if ([sharerClass isServiceAuthorized]) {
        
        //if ([sharerId isEqualToString:@"SHKDropbox"]) {
        //    [sharerClass getUserInfo];
        //}
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
    
    Class sharerClass = [self.sharers objectAtIndex:indexPath.row];
    
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

@end
