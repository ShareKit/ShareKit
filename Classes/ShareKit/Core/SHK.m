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
#import "SHKActivityIndicator.h"
#import "SHKConfiguration.h"
#import "SHKActionSheet.h"
#import "SHKOfflineSharer.h"
#import "SSKeychain.h"
#import "Reachability.h"
#import "SHKMail.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <MessageUI/MessageUI.h>
#include <sys/xattr.h>

NSString * SHKLocalizedStringFormat(NSString* key);
NSString * const SHKHideCurrentViewFinishedNotification = @"SHKHideCurrentViewFinished";

@interface SHK ()

@property (nonatomic, assign) UIViewController *rootViewController;
@property SEL showMethod;

@end

@implementation SHK

@synthesize currentView, pendingView, isDismissingView;
@synthesize rootViewController;
@synthesize offlineQueue;

static SHK *_currentHelper = nil;
BOOL SHKinit;


+ (SHK *)currentHelper
{
	if (_currentHelper == nil)
		_currentHelper = [[super allocWithZone:NULL] init];
	
	return _currentHelper;
}

+ (void)initialize
{
	[super initialize];
	
	if (!SHKinit)
	{
		SHKSwizzle([MFMailComposeViewController class], @selector(viewDidDisappear:), @selector(SHKviewDidDisappear:));
		
		if (NSClassFromString(@"MFMessageComposeViewController") != nil)
			SHKSwizzle([MFMessageComposeViewController class], @selector(viewDidDisappear:), @selector(SHKviewDidDisappear:));
		
		SHKinit = YES;
	}
}

- (void)dealloc
{
	[currentView release];
	[pendingView release];
	[offlineQueue release];
	[super dealloc];
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
	while (result.modalViewController != nil) result = result.modalViewController;
  
  NSAssert(result, @"ShareKit: There is no view controller to display from");
	return result;
}

- (UIViewController *)getCurrentRootViewController {
  
  UIViewController *result = nil;
  
  if (rootViewController) // If developer provieded a root view controler, use it
  {
    
    result = rootViewController;
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
  self.showMethod = @selector(showViewController:);
  
  BOOL isHidingPreviousView = [self hidePreviousView:vc];
  if (isHidingPreviousView) return;
  
  // Wrap the view in a nav controller if not already. Used for system views, such as share menu and share forms. BEWARE: this has to be called AFTER hiding previous. Sometimes hiding and presenting view is the same sharer, but with different SHKFormController on top (auth vs edit)
  
  NSAssert(vc.parentViewController == nil, @"vc must not be in the view hierarchy now"); //ios4 and older
  
  if ([UIViewController instancesRespondToSelector:@selector(presentingViewController)]) {
    NSAssert(vc.presentingViewController == nil, @"vc must not be in the view hierarchy now"); //ios5+
  }
  
	if (![vc isKindOfClass:[UINavigationController class]]) vc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
  
  [(UINavigationController *)vc navigationBar].barStyle = [SHK barStyle];
  [(UINavigationController *)vc toolbar].barStyle = [SHK barStyle];
  [(UINavigationController *)vc navigationBar].tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:,vc);
  
  [self presentVC:vc];
}

/* method for sharers with custom UI, e.g. all social.framework sharers, print etc */
- (void)showStandaloneViewController:(UIViewController *)vc {
  
  self.showMethod = @selector(presentVC:);
  
  BOOL isHidingPreviousView = [self hidePreviousView:vc];
  if (isHidingPreviousView) return;
  
  [self presentVC:vc];
}

- (void)presentVC:(UIViewController *)vc {
  
  BOOL isSocialOrTwitterComposeVc = [vc respondsToSelector:@selector(setInitialText:)];
  
  if ([vc respondsToSelector:@selector(modalPresentationStyle)] && !isSocialOrTwitterComposeVc)
    vc.modalPresentationStyle = [SHK modalPresentationStyleForController:vc];
  
  if ([vc respondsToSelector:@selector(modalTransitionStyle)] && !isSocialOrTwitterComposeVc)
    vc.modalTransitionStyle = [SHK modalTransitionStyle];
  
  UIViewController *topViewController = [self rootViewForUIDisplay];
  
  if ([UIViewController instancesRespondToSelector:@selector(presentViewController:animated:completion:)]) {
    [topViewController presentViewController:vc animated:YES completion:nil];
  } else {
    [topViewController presentModalViewController:vc animated:YES];
  }
  
  self.currentView = vc;
	self.pendingView = nil;
}

- (BOOL)hidePreviousView:(UIViewController *)VCToShow {
  
  // If a view is already being shown, hide it, and then try again
	if (currentView != nil) {
    
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
	if (isDismissingView)
		return;
	
	if (currentView != nil)
	{
		// Dismiss the modal view
		if ([currentView parentViewController] != nil)
		{
			self.isDismissingView = YES;
			[[currentView parentViewController] dismissModalViewControllerAnimated:animated];
		}
		// for iOS5
		else if([currentView respondsToSelector:@selector(presentingViewController)] &&
		        [currentView presentingViewController])
		{
			self.isDismissingView = YES;
      [[currentView presentingViewController] dismissViewControllerAnimated:animated completion:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
          [self viewWasDismissed];
          [[NSNotificationCenter defaultCenter] postNotificationName:SHKHideCurrentViewFinishedNotification object:nil];
        }];
      }];
    }
		
		else
			self.currentView = nil;
	}
}

- (void)showPendingView
{
  if (self.pendingView)
    [self performSelector:self.showMethod withObject:self.pendingView];
}

- (void)viewWasDismissed
{
	self.isDismissingView = NO;
	
	if (currentView != nil)
		self.currentView = nil;
	
	if (pendingView)
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

+ (UIModalTransitionStyle)modalTransitionStyle
{
	if ([SHKCONFIG(modalTransitionStyle) isEqualToString:@"UIModalTransitionStyleFlipHorizontal"])
		return UIModalTransitionStyleFlipHorizontal;
	
	else if ([SHKCONFIG(modalTransitionStyle) isEqualToString:@"UIModalTransitionStyleCrossDissolve"])
		return UIModalTransitionStyleCrossDissolve;
	
	else if ([SHKCONFIG(modalTransitionStyle) isEqualToString:@"UIModalTransitionStylePartialCurl"])
		return UIModalTransitionStylePartialCurl;
	
	return UIModalTransitionStyleCoverVertical;
}


#pragma mark -
#pragma mark Favorites


+ (NSArray *)favoriteSharersForType:(SHKShareType)type
{
	NSArray *favoriteSharers = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%i", SHKCONFIG(favsPrefixKey), type]];
  
	// set defaults
	if (favoriteSharers == nil)
	{
		switch (type)
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
				favoriteSharers = SHKCONFIG(defaultFavoriteFileSharers);
				break;
        
			default:
				favoriteSharers = [NSArray array];
		}
		
		// Save defaults to prefs
		[self setFavorites:favoriteSharers forType:type];
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
		[self setFavorites:favoriteSharers forType:type];
		
		[newFavs release];
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
		[self setFavorites:favoriteSharers forType:type];
		
		[newFavs release];
	}
	
	return favoriteSharers;
}

+ (void)pushOnFavorites:(NSString *)className forType:(SHKShareType)type
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
  
	NSMutableArray *favs = [[self favoriteSharersForType:type] mutableCopy];
	
	[favs removeObject:className];
	[favs insertObject:className atIndex:0];
	
	while (favs.count > [SHKCONFIG(maxFavCount) unsignedIntegerValue])
		[favs removeLastObject];
	
	[self setFavorites:favs forType:type];
	
	[favs release];
}

+ (void)setFavorites:(NSArray *)favs forType:(SHKShareType)type
{
	[[NSUserDefaults standardUserDefaults] setObject:favs forKey:[NSString stringWithFormat:@"%@%i", SHKCONFIG(favsPrefixKey), type]];
}

#pragma mark -
#pragma mark Credentials

// TODO someone with more keychain experience may want to clean this up.  The use of SFHFKeychainUtils may be unnecessary?

+ (NSString *)getAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId
{
#if TARGET_IPHONE_SIMULATOR
	// Using NSUserDefaults for storage is very insecure, but because Keychain only exists on a device
	// we use NSUserDefaults when running on the simulator to store objects.  This allows you to still test
	// in the simulator.  You should NOT modify in a way that does not use keychain when actually deployed to a device.
	return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@%@",SHKCONFIG(authPrefix),sharerId,key]];
#else
	return [SSKeychain passwordForService:[NSString stringWithFormat:@"%@%@",SHKCONFIG(authPrefix),sharerId]
                                account:key
                                  error:nil ];
#endif
}

+ (void)setAuthValue:(NSString *)value forKey:(NSString *)key forSharer:(NSString *)sharerId
{
#if TARGET_IPHONE_SIMULATOR
	// Using NSUserDefaults for storage is very insecure, but because Keychain only exists on a device
	// we use NSUserDefaults when running on the simulator to store objects.  This allows you to still test
	// in the simulator.  You should NOT modify in a way that does not use keychain when actually deployed to a device.
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:[NSString stringWithFormat:@"%@%@%@",SHKCONFIG(authPrefix),sharerId,key]];
#else
	[SSKeychain setPassword:value
               forService:[NSString stringWithFormat:@"%@%@",SHKCONFIG(authPrefix),sharerId]
                  account:key
                    error:nil];
#endif
}

+ (void)removeAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId
{
#if TARGET_IPHONE_SIMULATOR
	// Using NSUserDefaults for storage is very insecure, but because Keychain only exists on a device
	// we use NSUserDefaults when running on the simulator to store objects.  This allows you to still test
	// in the simulator.  You should NOT modify in a way that does not use keychain when actually deployed to a device.
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"%@%@%@",SHKCONFIG(authPrefix),sharerId,key]];
#else
	[SSKeychain deletePasswordForService:[NSString stringWithFormat:@"%@%@",SHKCONFIG(authPrefix),sharerId]
                               account:key
                                 error:nil];
#endif
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
    
    shareKitLibraryBundlePath = [[[NSBundle mainBundle] pathForResource:@"ShareKit" ofType:@"bundle"] retain];
  }
  return shareKitLibraryBundlePath;
}

static NSDictionary *sharersDictionary = nil;

+ (NSDictionary *)sharersDictionary
{
	if (sharersDictionary == nil)
  {
		sharersDictionary = [[NSDictionary dictionaryWithContentsOfFile:[[SHK shareKitLibraryBundlePath] stringByAppendingPathComponent:SHKCONFIG(sharersPlistName)]] retain];
  }
  
  //if user sets his own sharers plist - name only
  if (sharersDictionary == nil)
  {
    sharersDictionary = [[NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:SHKCONFIG(sharersPlistName)]] retain];
  }
  
  //if user sets his own sharers plist - complete path
  if (sharersDictionary == nil) {
    sharersDictionary = [[NSDictionary dictionaryWithContentsOfFile:SHKCONFIG(sharersPlistName)] retain];
  }
  
  NSAssert(sharersDictionary != nil, @"ShareKit: You do not have properly set sharersPlistName");
  
	
	return sharersDictionary;
}


#pragma mark -
#pragma mark Offline Support

+ (NSString *)offlineQueuePath
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cache = [paths objectAtIndex:0];
	NSString *SHKPath = [cache stringByAppendingPathComponent:@"SHK"];
	
	// Check if the path exists, otherwise create it
	if (![fileManager fileExistsAtPath:SHKPath]) {
		[fileManager createDirectoryAtPath:SHKPath withIntermediateDirectories:YES attributes:nil error:nil];
    [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:SHKPath]];
  }
	
	return SHKPath;
}

+ (NSString *)offlineQueueListPath
{
	NSString *offlinePathString = [[self offlineQueuePath] stringByAppendingPathComponent:@"SHKOfflineQueue.plist"];
  [[NSFileManager defaultManager] addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:offlinePathString]];
  return offlinePathString;
}

+ (NSMutableArray *)getOfflineQueueList
{
	return [[[NSArray arrayWithContentsOfFile:[self offlineQueueListPath]] mutableCopy] autorelease];
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
	
	// Generate a unique id for the share to use when saving associated files
	NSString *uid = [NSString stringWithFormat:@"%@-%i-%f-%i", sharerId, item.shareType, [[NSDate date] timeIntervalSince1970], arc4random()];
	
	
	// store image in cache
	if (item.shareType == SHKShareTypeImage && item.image)
		[UIImageJPEGRepresentation(item.image, 1) writeToFile:[[self offlineQueuePath] stringByAppendingPathComponent:uid] atomically:YES];
	
	// store file in cache
	else if (item.shareType == SHKShareTypeFile)
		[item.data writeToFile:[[self offlineQueuePath] stringByAppendingPathComponent:uid] atomically:YES];
	
	// Open queue list
	NSMutableArray *queueList = [self getOfflineQueueList];
	if (queueList == nil)
		queueList = [NSMutableArray arrayWithCapacity:0];
	
	// Add to queue list
	[queueList addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                        [item dictionaryRepresentation],@"item",
                        sharerId,@"sharer",
                        uid,@"uid",
                        nil]];
	
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
      [aQueue release];
    }
    
		SHKItem *item;
		NSString *sharerId, *uid;
		
		for (NSDictionary *entry in queueList)
		{
			item = [SHKItem itemFromDictionary:[entry objectForKey:@"item"]];
			sharerId = [entry objectForKey:@"sharer"];
			uid = [entry objectForKey:@"uid"];
			
			if (item != nil && sharerId != nil)
				[helper.offlineQueue addOperation:[[[SHKOfflineSharer alloc] initWithItem:item forSharer:sharerId uid:uid] autorelease]];
		}
		
		// Remove offline queue - TODO: only do this if everything was successful?
		[[NSFileManager defaultManager] removeItemAtPath:[self offlineQueueListPath] error:nil];
    
	}
}

#pragma mark -

+ (NSError *)error:(NSString *)description, ...
{
	va_list args;
  va_start(args, description);
  NSString *string = [[[NSString alloc] initWithFormat:description arguments:args] autorelease];
  va_end(args);
	
	return [NSError errorWithDomain:@"sharekit" code:1 userInfo:[NSDictionary dictionaryWithObject:string forKey:NSLocalizedDescriptionKey]];
}

#pragma mark -
#pragma mark Network

+ (BOOL)connected
{
	//return NO; // force for offline testing
	Reachability *hostReach = [Reachability reachabilityForInternetConnection];
	NetworkStatus netStatus = [hostReach currentReachabilityStatus];
	return !(netStatus == NotReachable);
}

#pragma mark -
#pragma mark Singleton System Overrides

+ (id)allocWithZone:(NSZone *)zone
{
  return [[self currentHelper] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

- (id)retain
{
  return self;
}

- (NSUInteger)retainCount
{
  return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
  //do nothing
}

- (id)autorelease
{
  return self;
}

@end


NSString * SHKStringOrBlank(NSString * value)
{
	return value == nil ? @"" : value;
}

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
	
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                         (CFStringRef)value.absoluteString,
                                                                         NULL,
                                                                         CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                         kCFStringEncodingUTF8);
  [result autorelease];
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

void SHKSwizzle(Class c, SEL orig, SEL newClassName)
{
  Method origMethod = class_getInstanceMethod(c, orig);
  Method newMethod = class_getInstanceMethod(c, newClassName);
  if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(c, newClassName, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

NSString* SHKLocalizedStringFormat(NSString* key)
{
  static NSBundle* bundle = nil;
  
  if (nil == bundle)
  {
    NSString* path = [[SHK shareKitLibraryBundlePath] stringByAppendingPathComponent:@"ShareKit.bundle"];
  
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES)
    {
      bundle = [[NSBundle bundleWithPath:path] retain];
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:[SHK shareKitLibraryBundlePath]] == YES)
    {
      bundle = [[NSBundle bundleWithPath:[SHK shareKitLibraryBundlePath]] retain];
    }
    
    NSCAssert(bundle != nil,@"ShareKit has been refactored to be used as Xcode subproject. Please follow the updated installation wiki and re-add it to the project. Please do not forget to clean project and clean build folder afterwards");
  }
  
  return [bundle localizedStringForKey:key value:key table:nil];
}

NSString* SHKLocalizedString(NSString* key, ...)
{
	// Localize the format
	NSString *localizedStringFormat = SHKLocalizedStringFormat(key);
	
	va_list args;
  va_start(args, key);
  NSString *string = [[[NSString alloc] initWithFormat:localizedStringFormat arguments:args] autorelease];
  va_end(args);
	
	return string;
}

@implementation NSFileManager (DoNotBackup)

- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
  const char* filePath = [[URL path] fileSystemRepresentation];
  const char* attrName = "com.apple.MobileBackup";
  if (&NSURLIsExcludedFromBackupKey == nil) {
    // iOS 5.0.1 and lower
    u_int8_t attrValue = 1;
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
  }
  else {
    // First try and remove the extended attribute if it is present
    int result = getxattr(filePath, attrName, NULL, sizeof(u_int8_t), 0, 0);
    if (result != -1) {
      // The attribute exists, we need to remove it
      int removeResult = removexattr(filePath, attrName, 0);
      if (removeResult == 0) {
        NSLog(@"Removed extended attribute on file %@", URL);
      }
    }
    
    // Set the new key
    return [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
  }
}

@end
