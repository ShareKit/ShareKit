//
//  SHK.h
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

#define SHK_VERSION @"0.2.1"

#import <Foundation/Foundation.h>

@class SHKActionSheet;
@class SHKItem;
@class SHKSharer;
@class SHKUploadInfo;

extern NSString * const SHKAuthDidFinishNotification;
extern NSString * const SHKSendDidStartNotification;
extern NSString * const SHKSendDidFailWithErrorNotification;
extern NSString * const SHKSendDidCancelNotification;

extern NSString * const SHKSendDidFinishNotification;
extern NSString * const SHKShareResponseKeyName;

extern NSString * const SHKUploadProgressNotification;
extern NSString * const SHKUploadProgressInfoKeyName;
extern NSString * const SHKUploadInfosDefaultsKeyName;

@interface SHK : NSObject 

@property (nonatomic, strong) UIViewController *currentView;
@property (nonatomic, strong) UIViewController *pendingView;
@property BOOL isDismissingView;

@property (nonatomic, strong) NSOperationQueue *offlineQueue;
@property (readonly) NSMutableOrderedSet *uploadProgressUserInfos;

#pragma mark -

+ (SHK *)currentHelper;

+ (NSDictionary *)sharersDictionary;

///returns array of classes of existing sharers which can share and require authentication.
+ (NSArray *)activeSharersRequiringAuthentication;

#pragma mark -
#pragma mark Sharer Management

///some sharers need to be retained until callback from UI or web service, otherwise they would be prematurely deallocated. Each sharer is responsible for removing itself on callback.
- (void)keepSharerReference:(SHKSharer *)sharer;
///Warning: this method removes only the first occurence of the sharer. If the sharer is on multiple indexes, the sharer's implementation is responsible to remove each one separately. The reason is pendingShare - the sharer might finish authentication, thus remove itself. Then it would be unavailable for callback after finishing subsequent pending share.
- (void)removeSharerReference:(SHKSharer *)sharer;

#pragma mark -
#pragma mark - Uploads Progress Management

/*!
 Each time there is a change of upload status (start, finish, failure, cancel) this method should be called. Saves the upload info reference to uploadProgressUserInfos property, and saves the change persistently to NSUserDefaults. Do not call this each time when upload bytes progress is reported, because saving to NSUserDefaults is expensive and unneccessary. Bytes progress is reported using SHKUploadProgressNotification.
 @param uploadProgressUserInfo
 Changed upload info
 */
- (void)uploadInfoChanged:(SHKUploadInfo *)uploadProgressUserInfo;

#pragma mark -
#pragma mark View Management

+ (void)setRootViewController:(UIViewController *)vc;

/* original show method, wraps the view to UINavigationViewController prior presenting, if not already a UINavigationViewController */
- (void)showViewController:(UIViewController *)vc;
/* displays sharers with custom UI - without wrapping */
- (void)showStandaloneViewController:(UIViewController *)vc;
/* returns current top view controller to display UI from */
- (UIViewController *)rootViewForUIDisplay;

- (void)hideCurrentViewControllerAnimated:(BOOL)animated;
- (void)viewWasDismissed;

+ (UIBarStyle)barStyle;
+ (UIModalPresentationStyle)modalPresentationStyleForController:(UIViewController *)controller;
+ (UIModalTransitionStyle)modalTransitionStyleForController:(UIViewController *)controller;

#pragma mark -
#pragma mark Favorites

+ (NSArray *)favoriteSharersForItem:(SHKItem *)item;
+ (void)pushOnFavorites:(NSString *)className forItem:(SHKItem *)item;
+ (void)setFavorites:(NSArray *)favs forItem:(SHKItem *)item;

+ (NSMutableArray *)sharersToShowInActionSheetForItem:(SHKItem *)item;

#pragma mark -
#pragma mark Credentials

+ (NSString *)getAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId;
+ (void)setAuthValue:(NSString *)value forKey:(NSString *)key forSharer:(NSString *)sharerId;
+ (void)removeAuthValueForKey:(NSString *)key forSharer:(NSString *)sharerId;

+ (void)logoutOfAll;
+ (void)logoutOfService:(NSString *)sharerId;

#pragma mark -
#pragma mark Offline Support

+ (NSString *)offlineQueuePath;
+ (NSString *)offlineQueueListPath;
+ (NSMutableArray *)getOfflineQueueList;
+ (void)saveOfflineQueueList:(NSMutableArray *)queueList;
+ (BOOL)addToOfflineQueue:(SHKItem *)item forSharer:(NSString *)sharerId;
+ (void)flushOfflineQueue;

#pragma mark -

+ (NSError *)error:(NSString *)description, ...;

#pragma mark -
#pragma mark Network

+ (BOOL)connected;

@end

NSString * SHKEncode(NSString * value);
NSString * SHKEncodeURL(NSURL * value);
NSString * SHKFlattenHTML(NSString * value, BOOL preserveLineBreaks);
NSString * SHKLocalizedString(NSString* key, ...);