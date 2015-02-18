//
//  SHKSharer_protected.h
//  ShareKit
//
//  Created by Vilem Kurz on 22/01/2014.
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

#import "SHKSharer.h"
#import "FormControllerCallback.h"
#import "SHKItem.h"

@class SHKUploadInfo;
@class SHKSession;

typedef enum
{
	SHKPendingNone,
	SHKPendingShare, //when ShareKit detects invalid credentials BEFORE user sends. User continues editing share content after login.
	SHKPendingRefreshToken, //when OAuth token expires
    SHKPendingSend, //when ShareKit detects invalid credentials AFTER user sends. Item is resent without showing edit dialogue (user edited already).
} SHKSharerPendingAction;

@class SHKFormController;
@class SHKFormOptionController;
@class SHKFile;

@interface SHKSharer ()

@property (strong) SHKItem *item;
@property (weak) SHKFormController *pendingForm;
@property (weak) SHKFormOptionController *curOptionController;
@property SHKSharerPendingAction pendingAction;

///Sharers, which are able to report upload progress (usually large file sharers, such as Dropbox or YouTube) store upload info statistics here.
@property (nonatomic, strong) SHKUploadInfo *uploadInfo;

///NSURLSession wrapper reference.
@property (nonatomic, strong) SHKSession *networkSession;

//readonly public properties
@property (nonatomic, strong) NSError *lastError;

///For use by sharers feeding local service's apps using UIDocumentInteractionController (instead of sharing via internet)
@property (nonatomic, strong) UIDocumentInteractionController* dic;
@property BOOL didSend;

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerId;
- (NSString *)sharerId;
+ (BOOL)canShareText;
+ (BOOL)canShareURL;
- (BOOL)requiresShortenedURL;
+ (BOOL)canShareImage;
+ (BOOL)canShareFile:(SHKFile *)file;
+ (BOOL)canGetUserInfo;

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare;

#pragma mark -
#pragma mark Initialization

- (id)init;

#pragma mark -
#pragma mark Share Item Save Methods

/*! used by subclasses when user has to quit the app during share process - e.g. during Facebook SSO trip to facebook app or browser. These methods save item temporarily to defaults and read it back. Data attachments (filedata, image) are stored as separate files in cache dir !*/
- (void)saveItemForLater:(SHKSharerPendingAction)inPendingAction;
///returns YES if item was found and restored.
- (BOOL)restoreItem;

// useful for handling custom posting error states
+ (void)clearSavedItem;

#pragma mark -
#pragma mark - Share Item URL Shortening

- (void)shortenURL;

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized;
- (void)promptAuthorization;
- (NSString *)getAuthValueForKey:(NSString *)key;

#pragma mark Authorization Form

- (void)authorizationFormShow;
- (FormControllerCallback)authorizationFormValidate;
- (FormControllerCallback)authorizationFormSave;
- (FormControllerCallback)authorizationFormCancel;
- (NSArray *)authorizationFormFields;
- (NSString *)authorizationFormCaption;
+ (NSArray *)authorizationFormFields;
+ (NSString *)authorizationFormCaption;

#pragma mark -
#pragma mark API Implementation

- (NSString *)tagStringJoinedBy:(NSString *)joinString allowedCharacters:(NSCharacterSet *)charset tagPrefix:(NSString *)prefixString tagSuffix:(NSString *)suffixString;

- (BOOL)validateItem;
- (BOOL)tryToSend;
- (BOOL)send;

#pragma mark -
#pragma mark UI Implementation

- (void)show;
- (void)hideActivityIndicator;
- (void)displayActivity:(NSString *)activityDescription;
- (void)displayCompleted:(NSString *)completionText;

///Some sharers instead of showing regular UI feed local service's apps with UIDocumentInteractionController. This is a convenience method for such sharers.
- (void)openInteractionControllerFileURL:(NSURL *)documentFileURL UTI:(NSString *)UTI annotation:(NSDictionary *)annotationDict;

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

/*!
 Each sharer should call this when actually starts sending the item to the service. Calling this causes SHKSendDidStartNotification to be sent, and calls sharerStartedSending: on the shareDelegate.
 */
- (void)sendDidStart;
/*!
 * Calls sendDidFinishWithResponse: with nil argument
 */
- (void)sendDidFinish;
/*!
 * Sends SHKSendDidFinishNotification with service's response in userInfo and calls sharerFinishedSending: on shareDelegate
 */
- (void)sendDidFinishWithResponse:(NSDictionary *)response;
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