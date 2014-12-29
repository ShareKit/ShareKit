//
//  DefaultSHKConfigurationDelegate.h
//  ShareKit
//
//  Created by Edward Dale on 10/16/10.

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

#import <Foundation/Foundation.h>

@class SHKFile;
@class UIColor;
@class NSString;
@class UIViewController;

@interface DefaultSHKConfigurator : NSObject 

- (NSString*)appName;
- (NSString*)appURL;
- (NSArray*)defaultFavoriteURLSharers;
- (NSArray*)defaultFavoriteImageSharers;
- (NSArray*)defaultFavoriteTextSharers;
- (NSArray*)defaultFavoriteFileSharers __attribute__((deprecated("use defaultFavoriteSharersForFile: instead")));
- (NSArray*)defaultFavoriteSharersForMimeType:(NSString *)mimeType __attribute__((deprecated("use defaultFavoriteSharersForFile: instead")));
- (NSArray*)defaultFavoriteSharersForFile:(SHKFile *)file;
- (NSString*)onenoteClientId;
- (NSString*)vkontakteAppId;
- (NSString*)facebookAppId;
- (NSString*)facebookLocalAppId;
- (NSArray*)facebookWritePermissions;
- (NSArray*)facebookReadPermissions;
- (NSNumber*)forcePreIOS6FacebookPosting;
- (NSString *)pocketConsumerKey;
- (NSString*)diigoKey;
- (NSNumber*)forcePreIOS5TwitterAccess;
- (NSString*)googlePlusClientId;
- (NSString*)twitterConsumerKey;
- (NSString*)twitterSecret;
- (NSString*)twitterCallbackUrl;
- (NSNumber*)twitterUseXAuth;
- (NSString*)twitterUsername;
- (NSString*)evernoteHost;
- (NSString*)evernoteConsumerKey;
- (NSString*)evernoteSecret;
- (NSString*)flickrConsumerKey;
- (NSString*)flickrSecretKey;
- (NSString*)flickrCallbackUrl;
- (NSString*)bitLyLogin;
- (NSString*)bitLyKey;
- (NSString*)linkedInConsumerKey;
- (NSString*)linkedInSecret;
- (NSString*)linkedInCallbackUrl;
- (NSString*)readabilityConsumerKey;
- (NSString*)readabilitySecret;
- (NSNumber*)readabilityUseXAuth;
- (NSString*)foursquareV2ClientId;
- (NSString*)foursquareV2RedirectURI;
- (NSString*)tumblrConsumerKey;
- (NSString*)tumblrSecret;
- (NSString*)tumblrCallbackUrl;
- (NSString*)hatenaConsumerKey;
- (NSString*)hatenaSecret;
- (NSString*)hatenaScope;
- (NSString *)plurkAppKey;
- (NSString *)plurkAppSecret;
- (NSString *)plurkCallbackURL;
- (NSNumber *)instagramLetterBoxImages;
- (UIColor *)instagramLetterBoxColor;
- (NSNumber *)instagramOnly;
- (NSString*)youTubeConsumerKey;
- (NSString*)youTubeSecret;
- (NSNumber *)useAppleShareUI;
- (NSNumber*)shareMenuAlphabeticalOrder;
- (NSString*)barStyle;
- (UIColor*)barTintForView:(UIViewController*)vc;
- (UIColor*)formFontColor;
- (UIColor*)formBackgroundColor;
- (NSString*)modalPresentationStyleForController:(UIViewController *)controller;
- (NSString*)modalTransitionStyleForController:(UIViewController *)controller;
- (NSNumber*)maxFavCount;
- (NSNumber*)autoOrderFavoriteSharers;
- (NSString*)favsPrefixKey;
- (NSString*)authPrefix;
- (NSString*)sharersPlistName;
- (NSNumber*)showActionSheetMoreButton;
- (NSNumber*)allowOffline;
- (NSNumber*)allowAutoShare;
- (Class)SHKShareMenuSubclass;
- (Class)SHKShareMenuCellSubclass;
- (Class)SHKFormControllerSubclass;
- (Class)SHKUploadsViewControllerSubclass;
- (Class)SHKAccountsViewControllerSubclass;
- (Class)SHKActivityIndicatorSubclass;
- (Class)SHKSharerDelegateSubclass;
//SHKDropbox
-(NSString *)dropboxAppKey;
-(NSString *)dropboxAppSecret;
-(NSString *)dropboxRootFolder;
-(NSNumber *)dropboxShouldOverwriteExistedFile;
//SHKBuffer
- (NSNumber *)bufferShouldShortenURLS;
//SHKImgur
- (NSString *)imgurClientID;
- (NSString *)imgurClientSecret;
- (NSString *)imgurCallbackURL;

#pragma mark - default values for sharer specific extension SHKItem properties
//SHKPrint
- (NSNumber*)printOutputType;
//SHKMail
- (NSArray *)mailToRecipients;
- (NSNumber*)isMailHTML;
- (NSNumber*)mailJPGQuality;
- (NSNumber*)sharedWithSignature;
//SHKFacebook
- (NSString *)facebookURLSharePictureURI;
- (NSString *)facebookURLShareDescription;
//SHKTextMessage
- (NSArray *)textMessageToRecipients;
//SHKInstagram and future others
-(NSString*) popOverSourceRect;
//SHKDropbox
- (NSString *)dropboxDestinationDirectory;

@end
