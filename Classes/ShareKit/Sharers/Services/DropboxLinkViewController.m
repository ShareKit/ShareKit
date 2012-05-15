//
//  RootViewController.m
//  DBRoulette
//
//  Created by Brian Smith on 6/29/10.
//  Copyright Dropbox, Inc. 2010. All rights reserved.
//

#import "DropboxLinkViewController.h"
#import <DropboxSDK/DropboxSDK.h>
#import "UploadViewController.h"

@interface DropboxLinkViewController ()

- (void)updateButtons;

@end


@implementation DropboxLinkViewController
@synthesize descriptionLabel;

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        self.title = @"Link Account";
    }
    return self;
}


- (void)didPressLink {
    if (![[DBSession sharedSession] isLinked]) {
		[[DBSession sharedSession] link];
        
        UploadViewController *uploadV = [[UploadViewController alloc]initWithNibName:@"UploadViewController" bundle:nil];
        [self.navigationController pushViewController:uploadV animated:NO];
        self.navigationController.navigationBarHidden = YES;
        [uploadV release];
        
    } else {
        [[DBSession sharedSession] unlinkAll];
        [[[[UIAlertView alloc] 
           initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked" 
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
        [self updateButtons];
    }
}

- (IBAction)didPressPhotos {
    [self.navigationController pushViewController:photoViewController animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateButtons];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Link Account";
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Dropbox background"]];
    self.navigationController.navigationBarHidden = YES;
    
    if ([[DBSession sharedSession] isLinked]) {
        
        UploadViewController *uploadV = [[UploadViewController alloc]initWithNibName:@"UploadViewController" bundle:nil];
        [self.navigationController pushViewController:uploadV animated:NO];
        self.navigationController.navigationBarHidden = YES;
        [uploadV release];
        
    }
}

- (void)viewDidUnload {
    [self setDescriptionLabel:nil];
    [linkButton release];
    linkButton = nil;
}

- (void)dealloc {
    [linkButton release];
    [photoViewController release];
    [descriptionLabel release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return toInterfaceOrientation == UIInterfaceOrientationPortrait;
    } else {
        return YES;
    }
}


#pragma mark private methods
@synthesize linkButton;
@synthesize photoViewController;

- (void)updateButtons {
    NSString* title = [[DBSession sharedSession] isLinked] ? @"Unlink Dropbox" : @"Link Dropbox";
    [linkButton setTitle:title forState:UIControlStateNormal];
    [self.descriptionLabel setText:[[DBSession sharedSession] isLinked] ? @"Press \"Unink Dropbox\" to unlink Dropbox from this application" : @"Press \"Link Dropbox\" and login to your account to Upload content"];
    self.navigationItem.rightBarButtonItem.enabled = [[DBSession sharedSession] isLinked];
}

@end

