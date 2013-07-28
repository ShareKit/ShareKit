//
//  ShareKitAppDelegate.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/4/10.
//  Copyright Idea Shower, LLC 2010. All rights reserved.
//

#import "ShareKitAppDelegate.h"
#import "RootViewController.h"

#import "SHKDropbox.h"
#import "SHKGooglePlus.h"
#import "SHKFacebook.h"
#import "EvernoteSDK.h"
#import "SHKBuffer.h"
#import "PocketAPI.h"

#import "SHKConfiguration.h"
#import "ShareKitDemoConfigurator.h"
#import "SHK.h"

@implementation ShareKitAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    // Override point for customization after app launch    
	
    //Here you load ShareKit submodule with app specific configuration
    DefaultSHKConfigurator *configurator = [[ShareKitDemoConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    
    window.rootViewController = navigationController;
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

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[SHKFacebook handleDidBecomeActive];
    [[EvernoteSession sharedSession] handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	// Save data if appropriate
	[SHKFacebook handleWillTerminate];
}

- (BOOL)application:(UIApplication *)application 
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    NSString* scheme = [url scheme];
    
    NSRange pocketPrefixKeyRange = [(NSString *)SHKCONFIG(pocketConsumerKey) rangeOfString:@"-"];
    NSRange range = {0, pocketPrefixKeyRange.location - 1};
    NSString *pocketPrefixKeyPart = [(NSString *)SHKCONFIG(pocketConsumerKey) substringWithRange:range];

    if ([scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]]) {
        return [SHKFacebook handleOpenURL:url];
    } else if ([scheme isEqualToString:@"com.cocoaminers.ShareKit-demo-app"]) {
        return [SHKGooglePlus handleURL:url sourceApplication:sourceApplication annotation:annotation];
    } else if ([scheme hasPrefix:[NSString stringWithFormat:@"db-%@", SHKCONFIG(dropboxAppKey)]]) {
        return [SHKDropbox handleOpenURL:url];
    } else if ([[NSString stringWithFormat:@"en-%@", [[EvernoteSession sharedSession] consumerKey]] isEqualToString:[url scheme]]) {
        return [[EvernoteSession sharedSession] canHandleOpenURL:url];
    } else if ([scheme hasPrefix:[NSString stringWithFormat:@"buffer%@", SHKCONFIG(bufferClientID)]]) {
        return [SHKBuffer handleOpenURL:url];
    }else if ([scheme hasPrefix:[NSString stringWithFormat:@"pocketapp%@", pocketPrefixKeyPart]]) {
        return [[PocketAPI sharedAPI] handleOpenURL:url];
    }

    
    return YES;
}

@end