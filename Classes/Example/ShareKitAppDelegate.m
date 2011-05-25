//
//  ShareKitAppDelegate.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import "ShareKitAppDelegate.h"
#import "RootViewController.h"

#import "SHKFacebook.h"
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
	
	navigationController.topViewController.title = SHKLocalizedString(@"Examples");
	[navigationController setToolbarHidden:NO];
	
	[self performSelector:@selector(testOffline) withObject:nil afterDelay:0.5];
	
	return YES;
}

- (void)testOffline
{	
	[SHK flushOfflineQueue];
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	// Save data if appropriate
}

- (BOOL)handleOpenURL:(NSURL*)url
{
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  NSNumber *index = [info objectForKey:@"FacebookURLTypeIndex"];
  if (! index) return YES;
  
  NSArray *urlTypes = [info objectForKey:@"CFBundleURLTypes"];
  if ((! urlTypes) || ([urlTypes count] <= [index integerValue])) return YES;
  
  NSDictionary *facebookURL = [urlTypes objectAtIndex:[index integerValue]];
  NSString *scheme = [[facebookURL objectForKey:@"CFBundleURLSchemes"] lastObject];
  if ([[url scheme] isEqualToString:scheme])
    return [SHKFacebook handleOpenURL:url];
  return YES;
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url 
  sourceApplication:(NSString *)sourceApplication 
         annotation:(id)annotation 
{
  return [self handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application 
      handleOpenURL:(NSURL *)url 
{
  return [self handleOpenURL:url];  
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}


@end

