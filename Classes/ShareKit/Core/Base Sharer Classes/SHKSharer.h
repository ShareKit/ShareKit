//
//  SHKSharer.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/8/10.

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

#import <UIKit/UIKit.h>

#import "SHKItem.h"
#import "FormControllerCallback.h"

@class SHKRequest;
@class SHKFormController;
@class SHKFormOptionController;
@class SHKFile;

@class SHKSharer;

@protocol SHKSharerDelegate <NSObject>

- (void)sharerStartedSending:(SHKSharer *)sharer;
- (void)sharerFinishedSending:(SHKSharer *)sharer;
- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin;
- (void)sharerCancelledSending:(SHKSharer *)sharer;
- (void)sharerShowBadCredentialsAlert:(SHKSharer *)sharer;
- (void)sharerShowOtherAuthorizationErrorAlert:(SHKSharer *)sharer;
@optional
- (void)sharerAuthDidFinish:(SHKSharer *)sharer success:(BOOL)success;	

@end

typedef enum 
{
	SHKPendingNone,
	SHKPendingShare, //when ShareKit detects invalid credentials BEFORE user sends. User continues editing share content after login.
	SHKPendingRefreshToken, //when OAuth token expires
    SHKPendingSend, //when ShareKit detects invalid credentials AFTER user sends. Item is resent without showing edit dialogue (user edited already). 
} SHKSharerPendingAction;

@interface SHKSharer : UINavigationController

@property (nonatomic, strong) id <SHKSharerDelegate> shareDelegate;

@property (strong) SHKItem *item;
@property (weak) SHKFormController *pendingForm;
@property (weak) SHKFormOptionController *curOptionController;
@property (nonatomic, strong) NSError *lastError;
@property BOOL quiet;
@property SHKSharerPendingAction pendingAction;

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle;
- (NSString *)sharerTitle;
+ (NSString *)sharerId;
- (NSString *)sharerId;
+ (BOOL)canShareText;
+ (BOOL)canShareURL;
- (BOOL)requiresShortenedURL;
+ (BOOL)canShareImage;
+ (BOOL)canShareFile:(SHKFile *)file;
+ (BOOL)canGetUserInfo;
+ (BOOL)shareRequiresInternetConnection;
+ (BOOL)canShareOffline;
+ (BOOL)requiresAuthentication;
+ (BOOL)canShareItem:(SHKItem *)item;
+ (BOOL)canAutoShare;

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare;
- (BOOL)shouldAutoShare;

#pragma mark -
#pragma mark Initialization

- (id)init;

#pragma mark -
#pragma mark Share Item Loading Convenience Methods

+ (id)shareItem:(SHKItem *)i;

- (void)loadItem:(SHKItem *)i;

+ (id)shareURL:(NSURL *)url;
+ (id)shareURL:(NSURL *)url title:(NSString *)title;

+ (id)shareImage:(UIImage *)image title:(NSString *)title;

+ (id)shareText:(NSString *)text;

+ (id)shareFile:(NSData *)file filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title __attribute__((deprecated("use shareFileData:filename:title or shareFilePath:title instead. Mimetype is derived from filename")));

// use if you share in-memory data.
+ (id)shareFileData:(NSData *)data filename:(NSString *)filename title:(NSString *)title;

//use if you share file from disk.
+ (id)shareFilePath:(NSString *)path title:(NSString *)title;

//only for services, which do not save credentials to the keychain, such as Twitter or Facebook. The result is complete user information (e.g. username) fetched from the service, saved to user defaults under the key kSHK<Service>UserInfo. When user does logout, it is meant to be deleted too. Useful, when you want to present some kind of logged user information (e.g. username) somewhere in your app.
+ (id)getUserInfo;

#pragma mark - 
#pragma mark Share Item Save Methods

/* used by subclasses when user has to quit the app during share process - e.g. during Facebook SSO trip to facebook app or browser. These methods save item temporarily to defaults and read it back. Data attachments (filedata, image) are stored as separate files in cache dir */
- (void)saveItemForLater:(SHKSharerPendingAction)inPendingAction;
- (BOOL)restoreItem;

// useful for handling custom posting error states
+ (void)clearSavedItem;

#pragma mark - 
#pragma mark - Share Item URL Shortening

- (void)shortenURL;

#pragma mark -
#pragma mark Commit Share

- (void)share;

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized;
- (BOOL)authorize;
- (void)promptAuthorization;
- (NSString *)getAuthValueForKey:(NSString *)key;

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

#pragma mark Authorization Form

- (void)authorizationFormShow;
- (FormControllerCallback)authorizationFormValidate;
- (FormControllerCallback)authorizationFormSave;
- (FormControllerCallback)authorizationFormCancel;
- (NSArray *)authorizationFormFields;
- (NSString *)authorizationFormCaption;
+ (NSArray *)authorizationFormFields;
+ (NSString *)authorizationFormCaption;
+ (void)logout;


#pragma mark -
#pragma mark API Implementation

- (NSString *)tagStringJoinedBy:(NSString *)joinString allowedCharacters:(NSCharacterSet *)charset tagPrefix:(NSString *)prefixString tagSuffix:(NSString *)suffixString;

- (BOOL)validateItem;
- (BOOL)tryToSend;
- (BOOL)send;

#pragma mark -
#pragma mark UI Implementation

- (void)show;

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type;
- (FormControllerCallback)shareFormValidate;
- (FormControllerCallback)shareFormSave;
- (FormControllerCallback)shareFormCancel;
- (void)setupFormController:(SHKFormController *)rootView withFields:(NSArray *)shareFormFields;

#pragma mark -
#pragma mark Pending Actions

- (void)tryPendingAction;

#pragma mark -
#pragma mark Delegate Notifications

- (void)sendDidStart;
- (void)sendDidFinish;
- (void)shouldReloginWithPendingAction:(SHKSharerPendingAction)action;
- (void)sendDidFailWithError:(NSError *)error;
- (void)sendDidFailWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin;
- (void)sendDidCancel;
/*  centralized error reporting */
- (void)authShowBadCredentialsAlert;
- (void)authShowOtherAuthorizationErrorAlert;
- (void)sendShowSimpleErrorAlert;
/*	called when an auth request returns. This is helpful if you need to use a service somewhere else in your
	application other than sharing. It lets you use the same stored auth creds and login screens.
 */
- (void)authDidFinish:(BOOL)success;	

@end



