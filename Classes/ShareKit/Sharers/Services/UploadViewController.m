//
//  UploadViewController.m
//  ShareKit
//
//  Created by George Termentzoglou on 4/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UploadViewController.h"

@implementation UploadViewController

@synthesize statusLabel;
@synthesize fileNameLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Dropbox background_2"]];

    
    //retrieve the locally saved file

     filePath = [[NSUserDefaults standardUserDefaults]valueForKey:@"DBfilePath"];
     fileName = [[NSUserDefaults standardUserDefaults]valueForKey:@"DBfileName"];

    [self.fileNameLabel setText:fileName];
}

- (void)viewDidUnload
{

    [self setFileNameLabel:nil];
    [self setStatusLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    
    [fileNameLabel release];
    [statusLabel release];
    [super dealloc];
}
- (IBAction)upload:(id)sender {
    
    NSString *destDir = @"/";
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [[self restClient] uploadFile:fileName toPath:destDir
                    withParentRev:nil fromPath:filePath];
    
    [self.statusLabel setText:@"Uploading..."];
    
}

- (IBAction)back:(id)sender {
    
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (IBAction)logout:(id)sender {
    
    [[DBSession sharedSession] unlinkAll];
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];

}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self.statusLabel setText:@"Upload Complete!"];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    [self.statusLabel setText:@"Upload Failed.Make sure you are connected to the Internet!"];
}

@end
