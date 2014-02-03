//
//  ExampleAccountsViewController.h
//  ShareKit
//
//  Created by Chris White on 1/22/13.
//
//

#import <UIKit/UIKit.h>

@interface SHKAccountsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

+ (instancetype)openFromViewController:(UIViewController *)rootViewController;

/*!
 If you wish to use customized cell, subclass SHKAccountsViewController and override this method.
 @result
 Class of your custom SHKAccountsViewCell subclass
 */
- (Class)accountsViewCellClass;

@end
