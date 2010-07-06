//
//  ShareKitAppDelegate.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShareKitAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

