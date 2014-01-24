//
//  SHKUploadsViewController.h
//  ShareKit
//
//  Created by Vilem Kurz on 23/01/2014.
//
//

#import <UIKit/UIKit.h>

@interface SHKUploadsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

+ (instancetype)openFromViewController:(UIViewController *)rootViewController;

@end
