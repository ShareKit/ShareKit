//
//  ExampleAccountsViewController.m
//  ShareKit
//
//  Created by Chris White on 1/22/13.
//
//

#import "ExampleAccountsViewController.h"

@interface ExampleAccountsViewController ()

@property(nonatomic, strong) UITableView *tableView;

@end

@implementation ExampleAccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
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

@end
