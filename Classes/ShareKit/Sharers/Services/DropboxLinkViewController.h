//
//  RootViewController.h
//  DBRoulette
//
//  Created by Brian Smith on 6/29/10.
//  Copyright Dropbox, Inc. 2010. All rights reserved.
//


@class DBRestClient;


@interface DropboxLinkViewController : UIViewController {
    UIButton* linkButton;
    UIViewController* photoViewController;
	DBRestClient* restClient;
}

- (IBAction)didPressLink;

@property (retain, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, retain) IBOutlet UIButton* linkButton;
@property (nonatomic, retain) UIViewController* photoViewController;

@end
