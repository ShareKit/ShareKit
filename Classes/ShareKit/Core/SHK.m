//
//  SHK.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/10/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHK.h"
#import "Singleton.h"
#import "Debug.h"

#import "SHKActivityIndicator.h"
#import "SHKConfiguration.h"
#import "SHKActionSheet.h"
#import "SHKOfflineSharer.h"
#import "SSKeychain.h"
#import "SHKReachability.h"
#import "SHKMail.h"
#import "SHKItem.h"
#import "SHKUploadInfo.h"

#import <objc/runtime.h>
#import <objc/message.h>
#import <MessageUI/MessageUI.h>

NSString * const SHKAuthDidFinishNotification = @"SHKAuthDidFinish";

NSString * const SHKSendDidStartNotification = @"SHKSendDidStartNotification";
NSString * const SHKSendDidFailWithErrorNotification = @"SHKSendDidFailWithError";
NSString * const SHKSendDidCancelNotification = @"SHKSendDidCancel";

NSString * const SHKSendDidFinishNotification = @"SHKSendDidFinish";
NSString * const SHKShareResponseKeyName = @"SHKShareResponseKeyName";

NSString * const SHKUploadProgressNotification = @"SHKUploadProgressNotification";
NSString * const SHKUploadProgressInfoKeyName = @"SHKUploadProgressInfoKeyName";
NSString * const SHKUploadInfosDefaultsKeyName = @"SHKUploadInfosDefaultsKeyName";

NSString * SHKLocalizedStringFormat(NSString* key);

@interface SHK ()

@property (nonatomic, weak) UIViewController *rootViewController;
@property BOOL wrapViewController;
@property (strong) NSMutableArray *sharerReferences;
@property (strong, nonatomic) NSMutableOrderedSet *uploadProgressUserInfos;

@end

@implementation SHK

BOOL SHKinit;

+ (SHK *)currentHelper {
    
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id)init {
    
    self = [super init];
    if (self) {
        _sharerReferences = [@[] mutableCopy];
        
        NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:SHKUploadInfosDefaultsKeyName];
      
        if (data) {
            NSArray *savedUploadUserInfosArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            _uploadProgressUserInfos = [[NSMutableOrderedSet alloc] initWithArray:savedUploadUserInfosArray];
        } else {
            _uploadProgressUserInfos = [[NSMutableOrderedSet alloc] initWithCapacity:10];
        }
    }
    return self;
}

- (void)dealloc {
    SHKLog(@"SHK base deallocated");
}

#pragma mark -
#pragma mark Sharer Management

- (void)keepSharerReference:(SHKSharer *)sharer {
    
    SHKLog(@"+++ %@ reference", [sharer sharerTitle]);
    [self.sharerReferences addObject:sharer];
}

- (void)removeSharerReference:(SHKSharer *)sharer {
    
    SHKLog(@"--- %@ reference", [sharer sharerTitle]);
    
    NSUInteger indexOfSharer = [self.sharerReferences indexOfObject:sharer];
    
    if (indexOfSharer != NSNotFound) {
        [self.sharerReferences removeObjectAtIndex:indexOfSharer];
    } else {
        SHKLog(@"Attempt to removeSharerReference NON Existing reference!!! Watch out, something is wrong with sharers implementation!!!");
    }
}

#pragma mark -
#pragma mark - Uploads Progress Management

- (void)uploadInfoChanged:(SHKUploadInfo *)uploadProgressUserInfo {
    
    if (uploadProgressUserInfo) {
        [self.uploadProgressUserInfos insertObject:uploadProgressUserInfo atIndex:0];
    }
    
    //save change to NSUserDefaults
    NSArray *array = [self.uploadProgressUserInfos array];
    NSData *uploadInfosData = [NSKeyedArchiver archivedDataWithRootObject:array];
    [[NSUserDefaults standardUserDefaults] setObject:uploadInfosData forKey:SHKUploadInfosDefaultsKeyName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark View Management

+ (void)setRootViewController:(UIViewController *)vc
{	
	SHK *helper = [self currentHelper];
	[helper setRootViewController:vc];	
}

- (UIViewController *)rootViewForUIDisplay {
    
    UIViewController *result = [self getCurrentRootViewController];
    
    // Find the top most view controller being displayed (so we can add the modal view to it and not one that is hidden)
	while (result.presentedViewController != nil) result = result.presentedViewController;
    
    NSAssert(result, @"ShareKit: There is no view controller to display from");
	return result;  
}

- (UIViewController *)getCurrentRootViewController {
    
    UIViewController *result = nil;
    
    if (self.rootViewController) // If developer provieded a root view controler, use it
    {
        
        result = self.rootViewController;
    }
    else // Try to find the root view controller programmically
	{
		// Find the top window (that is not an alert view or other window)
		UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
		if (topWindow.windowLevel != UIWindowLevelNormal)
		{
			NSArray *windows = [[UIApplication sharedApplication] windows];
			for(topWindow in windows)
			{
				if (topWindow.windowLevel == UIWindowLevelNormal)
					break;
			}
		}
		
		UIView *rootView = [[topWindow subviews] objectAtIndex:0];
		id nextResponder = [rootView nextResponder];
		
		if ([nextResponder isKindOfClass:[UIViewController class]])
			result = nextResponder;
		else if ([topWindow respondsToSelector:@selector(rootViewController)] && topWindow.rootViewController != nil)
            result = topWindow.rootViewController;
		else
			NSAssert(NO, @"ShareKit: Could not find a root view controller.  You can assign one manually by calling [[SHK currentHelper] setRootViewController:YOURROOTVIEWCONTROLLER].");
	}
    return result;
}

- (void)showViewController:(UIViewController *)vc
{
    self.wrapViewController = YES;
    
    BOOL isHidingPreviousView = [self hidePreviousView:vc];
    if (isHidingPreviousView) return;

    // Wrap the view in a nav controller if not already. Used for system views, such as share menu and share forms. BEWARE: this has to be called AFTER hiding previous. Sometimes hiding and presenting view is the same sharer, but with different SHKFormController on top (auth vs edit)

    NSAssert(vc.parentViewController == nil, @"vc must not be in the view hierarchy now"); //ios4 and older

    if ([UIViewController instancesRespondToSelector:@selector(presentingViewController)]) {
        NSAssert(vc.presentingViewController == nil, @"vc must not be in the view hierarchy now"); //ios5+
    }
    
	if (![vc isKindOfClass:[UINavigationController class]]) vc = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [(UINavigationController *)vc navigationBar].barStyle = [SHK barStyle];
    [(UINavigationController *)vc toolbar].barStyle = [SHK barStyle];
    [(UINavigationController *)vc navigationBar].tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,vc);
    
    [self presentVC:vc];
}

/* method for sharers with custom UI, e.g. all social.framework sharers, print etc */
- (void)showStandaloneViewController:(UIViewController *)vc {
    
    self.wrapViewController = NO;
    
    BOOL isHidingPreviousView = [self hidePreviousView:vc];
    if (isHidingPreviousView) return;    
        
    [self presentVC:vc];    
}

- (void)presentVC:(UIViewController *)vc {
    
    SEL selector = NSSelectorFromString(@"setInitialText:");
    BOOL isSocialOrTwitterComposeVc = [vc respondsToSelector:selector];

    if ([vc respondsToSelector:@selector(modalPresentationStyle)] && !isSocialOrTwitterComposeVc)
        vc.modalPresentationStyle = [SHK modalPresentationStyleForController:vc];
    
    if ([vc respondsToSelector:@selector(modalTransitionStyle)] && !isSocialOrTwitterComposeVc)
        vc.modalTransitionStyle = [SHK modalTransitionStyleForController:vc];
    
    UIViewController *topViewController = [self rootViewForUIDisplay];
    [topViewController presentViewController:vc animated:YES completion:nil];

    self.currentView = vc;
	self.pendingView = nil;
}

- (BOOL)hidePreviousView:(UIViewController *)VCToShow {
    
    // If a view is already being shown, hide it, and then try again
	if (self.currentView != nil) {
        
		self.pendingView = VCToShow;
		[self hideCurrentViewControllerAnimated:YES];
        return YES;
	
    }
    return NO;
}

- (void)hideCurrentViewController
{
	[self hideCurrentViewControllerAnimated:YES];
}

- (void)hideCurrentViewControllerAnimated:(BOOL)animated
{
	if (self.isDismissingView)
		return;
	
	if (self.currentView != nil)
	{
		// Dismiss the modal view
		if ([self.currentView presentingViewController])
		{
			self.isDismissingView = YES;            
            [[self.currentView presentingViewController] dismissViewControllerAnimated:animated completion:^{
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self viewWasDismissed];
                }];
            }];
        }
		else
        {
			self.currentView = nil;
        }
	}
}

- (void)showPendingView
{
    if (self.wrapViewController) {
        [self showViewController:self.pendingView];
    } else {
        [self presentVC:self.pendingView];
    }
}

- (void)viewWasDismissed
{
	self.isDismissingView = NO;
	
	if (self.currentView != nil)
		self.currentView = nil;
	
	if (self.pendingView)
	{
		// This is an ugly way to do it, but it works.
		// There seems to be an issue chaining modal views otherwise
		// See: http://github.com/ideashower/ShareKit/issues#issue/24
		[self performSelector:@selector(showPendingView) withObject:nil afterDelay:0.02];
		return;
	}
}
										   		
+ (UIBarStyle)barStyle
{
	if ([SHKCONFIG(barStyle) isEqualToString:@"UIBarStyleBlack"])
		return UIBarStyleBlack;
	
	else if ([SHKCONFIG(barStyle) isEqualToString:@"UIBarStyleBlackOpaque"])
		return UIBarStyleBlackOpaque;
	
	else if ([SHKCONFIG(barStyle) isEqualToString:@"UIBarStyleBlackTranslucent"])
		return UIBarStyleBlackTranslucent;
	
	return UIBarStyleDefault;
}

+ (UIModalPresentationStyle)modalPresentationStyleForController:(UIViewController *)controller
{
	NSString *styleString = SHKCONFIG_WITH_ARGUMENT(modalPresentationStyleForController:, controller);
	
	if ([styleString isEqualToString:@"UIModalPresentationFullScreen"])
		return UIModalPresentationFullScreen;
	
	else if ([styleString isEqualToString:@"UIModalPresentationPageSheet"])
		return UIModalPresentationPageSheet;
	
	else if ([styleString isEqualToString:@"UIModalPresentationFormSheet"])
		return UIModalPresentationFormSheet;
	
	return UIModalPresentationCurrentContext;
}

+ (UIModalTransitionStyle)modalTransitionStyleForController:(UIViewController *)controller
{
    NSString *transitionString = SHKCONFIG_WITH_ARGUMENT(modalTransitionStyleForController:, controller);
    
	if ([transitionString isEqualToString:@"UIModalTransitionStyleFlipHorizontal"])
		return UIModalTransitionStyleFlipHorizontal;
	
	else if ([transitionString isEqualToString:@"UIModalTransitionStyleCrossDissolve"])
		return UIModalTransitionStyleCrossDissolve;
	
	else if ([transitionString isEqualToString:@"UIModalTransitionStylePartialCurl"])
		return UIModalTransitionStylePartialCurl;
	
	return UIModalTransitionStyleCoverVertical;
}


#pragma mark -
#pragma mark Favorites

+ (NSArray *)favoriteSharersForItem:(SHKItem *)item;
{	
	
    NSArray *favoriteSharers = [[NSUserDefaults standardUserDefaults] objectForKey:[self favoritesKeyForItem:item]];
    
    //temporary check for iOS sharers. They were separated from original sharers such as SHKFacebook. Under certain circumstances this caused no sharers in shareMenu, see https://github.com/ShareKit/ShareKit/issues/885.
    BOOL favoritesContainSoloLegacyFacebook = [favoriteSharers containsObject:@"SHKFacebook"] && ![favoriteSharers containsObject:@"SHKiOSFacebook"];
    if (favoritesContainSoloLegacyFacebook) {
        NSMutableArray *mutableFavoriteSharers = [favoriteSharers mutableCopy];
        [mutableFavoriteSharers addObject:@"SHKiOSFacebook"];
        favoriteSharers = mutableFavoriteSharers;
    }
    BOOL favoritesContainSoloLegacyTwitter = [favoriteSharers containsObject:@"SHKTwitter"] && ![favoriteSharers containsObject:@"SHKiOSTwitter"];
    if (favoritesContainSoloLegacyTwitter) {
        NSMutableArray *mutableFavoriteSharers = [favoriteSharers mutableCopy];
        [mutableFavoriteSharers addObject:@"SHKiOSTwitter"];
        favoriteSharers = mutableFavoriteSharers;
    }
		
	// set defaults
	if (favoriteSharers == nil)
	{
		switch (item.shareType)
		{
			case SHKShareTypeURL:
				favoriteSharers = SHKCONFIG(defaultFavoriteURLSharers);
				break;
				
			case SHKShareTypeImage:
				favoriteSharers = SHKCONFIG(defaultFavoriteImageSharers);
				break;
				
			case SHKShareTypeText:
				favoriteSharers = SHKCONFIG(defaultFavoriteTextSharers);
				break;
				
			case SHKShareTypeFile:
				favoriteSharers = SHKCONFIG_WITH_ARGUMENT(defaultFavoriteSharersForMimeType:,item.file.mimeType);
				break;
			
			default:
				favoriteSharers = [NSArray array];
		}
		
		// Save defaults to prefs
		[self setFavorites:favoriteSharers forItem:item];
	}
    
    // Remove all sharers which are not part of the SHKSharers.plist
    NSDictionary *sharersDict = [self sharersDictionary];
    NSArray *keys = [sharersDict allKeys];
    NSMutableSet *allAvailableSharers = [NSMutableSet set];
    for (NSString *key in keys) {
        NSArray *sharers = [sharersDict objectForKey:key];
        [allAvailableSharers addObjectsFromArray:sharers];
    }
    NSMutableSet *favoriteSharersSet = [NSMutableSet setWithArray:favoriteSharers];
    [favoriteSharersSet minusSet:allAvailableSharers];
    if ([favoriteSharersSet count] > 0)
    {
        NSMutableArray *newFavs = [favoriteSharers mutableCopy];
		for(NSString *sharerId in favoriteSharersSet)
		{
			[newFavs removeObject:sharerId];
		}
        
        // Update
		favoriteSharers = [NSArray arrayWithArray:newFavs];
		[self setFavorites:favoriteSharers forItem:item];
		
    }
	
	// Make sure the favorites are not using any exclusions, remove them if they are.
	NSArray *exclusions = [[NSUserDefaults standardUserDefaults] objectForKey:@"SHKExcluded"];
	if (exclusions != nil)
	{
		NSMutableArray *newFavs = [favoriteSharers mutableCopy];
		for(NSString *sharerId in exclusions)
		{
			[newFavs removeObject:sharerId];
		}
		
		// Update
		favoriteSharers = [NSArray arrayWithArray:newFavs];
		[self setFavorites:favoriteSharers forItem:item];
		
	}
	
	return favoriteSharers;
}

+ (void)pushOnFavorites:(NSString *)className forItem:(SHKItem *)item
{
    if(![SHKCONFIG(autoOrderFavoriteSharers) boolValue]) return;
    
    NSArray *exclusions = [[NSUserDefaults standardUserDefaults] objectForKey:@"SHKExcluded"];
    if (exclusions != nil)
	{
		for(NSString *sharerId in exclusions)
		{
			if([className isEqualToString:sharerId]) return;
		}
	}
    
	NSMutableArray *favs = [[self favoriteSharersForItem:item] mutableCopy];
	
	[favs removeObject:className];
	[favs insertObject:className atIndex:0];
	
	while (favs.count > [SHKCONFIG(maxFavCount) unsignedIntegerValue])
		[favs removeLastObject];
	
	[self setFavorites:favs forItem:item];
	
}

+ (void)setFavorites:(NSArray *)favs forItem:(SHKItem *)item
{
    [[NSUserDefaults standardUserDefaults] setObject:favs forKey:[self favoritesKeyForItem:item]];
}

+ (NSString *)favoritesKeyForItem:(SHKItem *)item {
    
    NSString *result = nil;
    if (item.shareType == SHKShareTypeFile) {
        result = [NSString stringWithFormat:@"%@%@", SHKCONFIG(favsPrefixKey), item.file.mimeType];
    } else {
        result = [NSString stringWithFormat:@"%@%i", SHKCONFIG(favsPrefixKey), item.shareType];
    }
    return result;
}

+ (NSMutableArray *)sharersToShowInActionSheetForItem:(SHKItem *)item {
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:0];
    NSArray *favoriteSharers = [SHK favoriteSharersForItem:item];
    
    // Add buttons for each favorite sharer
    id class;
    for(NSString *sharerId in favoriteSharers)
    {
        //Do not add buttons for sharers, which are not able to share item
        class = NSClassFromString(sharerId);
        if ([class canShare] && [class canShareItem:item])
        {
            [result addObject:sharerId];
        }
    }
    return result;    
}

#pragma mark -
#pragma mark Credentials

// TODO someone with more keychain experience may want to clean this up.  The use of SFHFKeychainUtils may be unnecessary?

+ (NSString *)getAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId
{

    return [SSKeychain passwordForService:[NSString stringWithFormat:@"%@%@",SHKCONFIG(authPrefix),sharerId]
                                  account:key
                                    error:nil ];
}

+ (void)setAuthValue:(NSString *)value forKey:(NSString *)key forSharer:(NSString *)sharerId
{
    [SSKeychain setPassword:value
                 forService:[NSString stringWithFormat:@"%@%@",SHKCONFIG(authPrefix),sharerId]
                    account:key
                      error:nil];
}

+ (void)removeAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId
{
    [SSKeychain deletePasswordForService:[NSString stringWithFormat:@"%@%@",SHKCONFIG(authPrefix),sharerId]
                                 account:key
                                   error:nil];
}

+ (void)logoutOfAll
{
	NSArray *sharers = [[SHK sharersDictionary] objectForKey:@"services"];
	for (NSString *sharerId in sharers)
		[self logoutOfService:sharerId];
}

+ (void)logoutOfService:(NSString *)sharerId
{	
	[NSClassFromString(sharerId) logout];	
}


#pragma mark -

static NSString *shareKitLibraryBundlePath = nil;

+ (NSString *)shareKitLibraryBundlePath
{
    if (shareKitLibraryBundlePath == nil) {
        
        shareKitLibraryBundlePath = [[NSBundle bundleForClass:[SHK class]] pathForResource:@"ShareKit" ofType:@"bundle"];
    }
    return shareKitLibraryBundlePath;
}

static NSDictionary *sharersDictionary = nil;

+ (NSDictionary *)sharersDictionary
{
	if (sharersDictionary == nil)
    {        
		sharersDictionary = [NSDictionary dictionaryWithContentsOfFile:[[SHK shareKitLibraryBundlePath] stringByAppendingPathComponent:SHKCONFIG(sharersPlistName)]];
    }
    
    //if user sets his own sharers plist - name only
    if (sharersDictionary == nil) 
    {
        sharersDictionary = [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SHKCONFIG(sharersPlistName)]];
    }
    
    //if user sets his own sharers plist - complete path
    if (sharersDictionary == nil) {
        sharersDictionary = [NSDictionary dictionaryWithContentsOfFile:SHKCONFIG(sharersPlistName)];
    }
    
    NSAssert(sharersDictionary != nil, @"ShareKit: You do not have properly set sharersPlistName");
    
	
	return sharersDictionary;
}

+ (NSArray *)activeSharersRequiringAuthentication {
    
    NSDictionary *sharersDictionary = [SHK sharersDictionary];
    NSArray *services = [sharersDictionary objectForKey:@"services"];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[services count]];
    for (NSString *sharer in services) {
        Class sharerClass = NSClassFromString(sharer);
        if (sharerClass && [sharerClass canShare] && [sharerClass requiresAuthentication]) {
            [result addObject:sharerClass];
        }
    }
    return result;
}

#pragma mark -
#pragma mark Offline Support

//TODO change to URL bookmarks
+ (NSString *)offlineQueuePath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cache = [paths objectAtIndex:0];
	NSString *SHKPath = [cache stringByAppendingPathComponent:@"SHK"];
	
	// Check if the path exists, otherwise create it
	if (![fileManager fileExistsAtPath:SHKPath]) {
		[fileManager createDirectoryAtPath:SHKPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
	
	return SHKPath;
}

+ (NSString *)offlineQueueListPath
{
	NSString *offlinePathString = [[self offlineQueuePath] stringByAppendingPathComponent:@"SHKOfflineQueue.plist"];
    return offlinePathString;
}

+ (NSMutableArray *)getOfflineQueueList
{
	//TODO:should do this off the main thread
    return [[NSArray arrayWithContentsOfFile:[self offlineQueueListPath]] mutableCopy];
}

+ (void)saveOfflineQueueList:(NSMutableArray *)queueList
{
	[queueList writeToFile:[self offlineQueueListPath] atomically:YES]; // TODO - should do this off of the main thread	
}

+ (BOOL)addToOfflineQueue:(SHKItem *)item forSharer:(NSString *)sharerId
{
	if([SHKCONFIG(allowOffline) boolValue] == FALSE){
		return NO;
	}
	
	// Open queue list
	NSMutableArray *queueList = [self getOfflineQueueList];
	if (queueList == nil)
		queueList = [NSMutableArray arrayWithCapacity:0];
	
	// Add to queue list
	[queueList addObject:@{@"item": [NSKeyedArchiver archivedDataWithRootObject:item], @"sharer": sharerId}];
	
	[self saveOfflineQueueList:queueList];
	
	return YES;
}

+ (void)flushOfflineQueue
{
	// TODO - if an item fails, after all items are shared, it should present a summary view and allow them to see which items failed/succeeded
	
	// Check for a connection
	if (![self connected])
		return;
	
	// Open list
	NSMutableArray *queueList = [self getOfflineQueueList];
	
	// Run through each item in the quietly in the background
	// TODO - Is this the best behavior?  Instead, should the user confirm sending these again?  Maybe only if it has been X days since they were saved?
	//		- want to avoid a user being suprised by a post to Twitter if that happens long after they forgot they even shared it.
	if (queueList != nil)
	{
		SHK *helper = [self currentHelper];
		
		if (helper.offlineQueue == nil) {
            NSOperationQueue *aQueue = [[NSOperationQueue alloc] init];
			helper.offlineQueue = aQueue;	
        }
			
		for (NSDictionary *entry in queueList)
		{
            [helper.offlineQueue addOperation:[[SHKOfflineSharer alloc] initWithDictionary:entry]];
		}
		
		// Remove offline queue - TODO: only do this if everything was successful?
		[[NSFileManager defaultManager] removeItemAtPath:[self offlineQueueListPath] error:nil];

	}
}

#pragma mark -

+ (NSError *)error:(NSString *)description, ...
{
	NSDictionary *userInfo = nil;

	if (description) {
		va_list args;
		va_start(args, description);
		NSString *string = [[NSString alloc] initWithFormat:description arguments:args];
		va_end(args);

		userInfo = [NSDictionary dictionaryWithObject:string forKey:NSLocalizedDescriptionKey];
	}

	return [NSError errorWithDomain:@"sharekit" code:1 userInfo:userInfo];
}

#pragma mark -
#pragma mark Network

+ (BOOL)connected 
{
	//return NO; // force for offline testing
	SHKReachability *hostReach = [SHKReachability reachabilityForInternetConnection];	
	NetworkStatus netStatus = [hostReach currentReachabilityStatus];	
	return !(netStatus == NotReachable);
}

@end

NSString * SHKEncode(NSString * value)
{
	if (value == nil)
		return @"";
	
	NSString *string = value;
	
	string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	string = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	string = [string stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
    string = [string stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    string = [string stringByReplacingOccurrencesOfString:@"#" withString:@"%23"];
    string = [string stringByReplacingOccurrencesOfString:@"!" withString:@"%21"];
    string = [string stringByReplacingOccurrencesOfString:@"@" withString:@"%40"];
	
	return string;	
}

NSString * SHKEncodeURL(NSURL * value)
{
	if (value == nil)
		return @"";
	
	NSString *result = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                           (__bridge CFStringRef)value.absoluteString,
                                                                           NULL,
																		   CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                           kCFStringEncodingUTF8);
	return result;
}

NSString * SHKFlattenHTML(NSString * value, BOOL preserveLineBreaks)
{
    // Modified from http://rudis.net/content/2009/01/21/flatten-html-content-ie-strip-tags-cocoaobjective-c
    NSScanner *scanner;
    NSString *text = nil;
    
    scanner = [NSScanner scannerWithString:value];
    
    while ([scanner isAtEnd] == NO) 
    {
        [scanner scanUpToString:@"<" intoString:NULL]; 
        [scanner scanUpToString:@">" intoString:&text];
        
        value = [value stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@" "];
        
    }
    
    if (preserveLineBreaks == NO)
    {
        value = [value stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];	
}

NSString* SHKLocalizedStringFormat(NSString* key)
{
  static NSBundle* bundle = nil;
  if (nil == bundle) {
      
      NSString *path = [SHK shareKitLibraryBundlePath];
      bundle = [NSBundle bundleWithPath:path];
      NSCAssert(bundle != nil,@"ShareKit has been refactored to be used as Xcode subproject. Please follow the updated installation wiki and re-add it to the project. Please do not forget to clean project and clean build folder afterwards. In case you use CocoaPods override - (NSNumber *)isUsingCocoaPods; method in your configurator subclass and return [NSNumber numberWithBool:YES]");
  }
  NSString *result = [bundle localizedStringForKey:key value:nil table:nil];
  return result;
}

NSString* SHKLocalizedString(NSString* key, ...) 
{
	// Localize the format
	NSString *localizedStringFormat = SHKLocalizedStringFormat(key);
	
	va_list args;
    va_start(args, key);
    NSString *string = [[NSString alloc] initWithFormat:localizedStringFormat arguments:args];
    va_end(args);
	
	return string;
}