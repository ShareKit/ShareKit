//
//  SHKSharer.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/8/10.

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

@class SHKSharer;

@protocol SHKSharerDelegate <NSObject>

- (void)sharerStartedSending:(SHKSharer *)sharer;
- (void)sharerFinishedSending:(SHKSharer *)sharer;
- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin;
- (void)sharerCancelledSending:(SHKSharer *)sharer;
- (void)sharerShowBadCredentialsAlert:(SHKSharer *)sharer;
- (void)sharerShowOtherAuthorizationErrorAlert:(SHKSharer *)sharer;
- (void)hideActivityIndicatorForSharer:(SHKSharer *)sharer;
- (void)displayActivity:(NSString *)activityDescription forSharer:(SHKSharer *)sharer;
- (void)displayCompleted:(NSString *)completionText forSharer:(SHKSharer *)sharer;
- (void)showProgress:(CGFloat)progress forSharer:(SHKSharer *)sharer;
@optional
- (void)sharerAuthDidFinish:(SHKSharer *)sharer success:(BOOL)success;	

@end

#import "SHKSessionDelegate.h"

@class SHKItem;

@interface SHKSharer : UINavigationController <SHKSessionDelegate, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) id <SHKSharerDelegate> shareDelegate;

///holds last error encountered by sharer. Useful if you need to present it to the user.
@property (readonly, nonatomic, strong) NSError *lastError;

///YES means no alerts, no activity indicators are displayed during the share process.
@property BOOL quiet;

@property (readonly, strong) SHKItem *item;

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle;
- (NSString *)sharerTitle;
+ (BOOL)canShareItem:(SHKItem *)item;
+ (BOOL)shareRequiresInternetConnection;
+ (BOOL)canShareOffline;
+ (BOOL)requiresAuthentication;
+ (BOOL)canAutoShare;

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare;

#pragma mark -
#pragma mark Share Item Loading Convenience Methods

///Shares the item immediately
+ (id)shareItem:(SHKItem *)i;

///Loads item without sharing. Useful, if you wish to specify your own delegate, or otherwise setup the sharer. Do not forget to call 'share' method to actually share the item.
- (void)loadItem:(SHKItem *)i;

+ (id)shareURL:(NSURL *)url;
+ (id)shareURL:(NSURL *)url title:(NSString *)title;

+ (id)shareImage:(UIImage *)image title:(NSString *)title;

+ (id)shareText:(NSString *)text;

+ (id)shareFile:(NSData *)file filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title __attribute__((deprecated("use shareFileData:filename:title or shareFilePath:title instead. Mimetype is derived from filename")));

/// use if you share in-memory data.
+ (id)shareFileData:(NSData *)data filename:(NSString *)filename title:(NSString *)title;

///use if you share file from disk.
+ (id)shareFilePath:(NSString *)path title:(NSString *)title;

///only for services, which do not save credentials to the keychain, such as Twitter or Facebook. The result is complete user information (e.g. username) fetched from the service, saved to user defaults under the key kSHK<Service>UserInfo. When user does logout, it is meant to be deleted too. Useful, when you want to present some kind of logged user information (e.g. username) somewhere in your app.
+ (id)getUserInfo;

#pragma mark -
#pragma mark Commit Share

- (void)share;
- (void)cancel;

#pragma mark -
#pragma mark Authentication

/*!
 * Authorizes the sharer, without sharing anything.
 *
 * @return If service is already authorized, returns YES. Otherwise returns NO and presents authorization form.
 */
- (BOOL)authorize;

/*!
 * Convenient method for getting authorization status for particular service.
 *
 * @return If any user is authorized, returns YES, otherwise nil.
 */
+ (BOOL)isServiceAuthorized;

/*!
 * Convenient method for getting username, if any user is logged in.
 *
 * @return If any user is authorized, returns username, otherwise nil. For this method to work for OAuth sharer, this has to implement canGetUserInfo, otherwise returns nil.
 */
+ (NSString *)username;
+ (void)logout;

@end