//
//  ShareKitAppDelegate.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import "ShareKitAppDelegate.h"
#import "RootViewController.h"

#import "SHKReadItLater.h"
#import "SHKFacebook.h"

@implementation ShareKitAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    // Override point for customization after app launch    
	
	[window addSubview:[navigationController view]];
    [window makeKeyAndVisible];
	
	navigationController.topViewController.title = @"Examples";
	[navigationController setToolbarHidden:NO];
	
	[self performSelector:@selector(test) withObject:nil afterDelay:0.5];
	
	return YES;
}

- (void)test
{	
	[SHK flushOfflineQueue];
	//[SHKFacebook shareURL:[NSURL URLWithString:@"http://ideashower.com"]];	
}

- (void)test2
{
	[[SHKActivityIndicator currentIndicator] displayCompleted:@"Saved!"];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

