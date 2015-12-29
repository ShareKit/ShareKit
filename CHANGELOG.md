- VKontakte video share

**4.0.10 (2015-12-24)**
- Fixed podspec (all sharers now work via cocoapods) + project. Sorry it took so long... but here it is, finally
- Facebook iOS SDK updated to 3.24.1
- Deployment target raised to 7.0 (due to Facebook-iOS-SDK)

**4.0.3**
- added WhatsApp sharer, capable of all types of shares
- Facebook iOS SDK is updated to 3.22

**4.0.0**
- **Breaking change**: deprecated SHKActionSheet, introduced SHKAlertController (see #992)

**3.0.2**
- GooglePlus sdk updated to 1.7.1
- the demo app is not a part of this repo anymore. You can find it [here](https://github.com/ShareKit/ShareKit-Demo-App). The reasons for this change are in the [commit description](https://github.com/ShareKit/ShareKit/commit/eb095f516d9289cafdfe10eff7a28a641b174328).

**3.0.1**
- new (optional) html formatting for SHKTextMessage (via item.isHTMLText)

**3.0.0**
- simplified and reworked SHKFacebook. It was too complicated to keep it reliable. Updated to use Facebook-ios-sdk 3.16. Added file upload status reporting. **Breaking changes**:
    1. SHKFacebook does SSO authorisation only. If you wish to use SSO for users without account in iOS and social.framework for others see the implementation of `- (NSNumber*)forcePreIOS6FacebookPosting` in `DefaultSHKConfigurator`
    2. SHKFacebook no longer exposes reference to FBRequestConnection. Now each SHKFacebook instance encapsulates one and only one FBRequestConnection.
- added Open in 1Password action
- added Open in Chrome action

**2.5.9**
- Added Pinterest sharer. In case you do subproject install you need to add Pinterest.embeddedframework to link binary with libraries AND copy bundle resources build phases of your app's target.
- UI enhancement: if URL is a picture, or item.URLPictureURI is set the image is fetched and shown in share dialogue.
- Added new configuration item SHKSharerDelegateSubclass. You can easily enhance UI reaction to various share events. However, if you only want to change HUD, you can rather override SHKActivityIndicatorSubclass

**2.5.7**
- added OneNote sharer. You need to add LiveSDK.framework to link binary with libraries AND copy bundle resources build phases of your app's target.
- if the service supports it file uploads utilise NSInputStream (without loading complete file into memory)
- more sharers can report upload progress (Flickr, Plurk, Tumblr, iOSTwitter, iOSFacebook)
- added SHKAccountsViewController. It displays a list of available services, their authorisation status, logged in username and allows to login/logoff. 
- more sharers canGetUserInfo:Hatena, Foursquare, Evernote. Now all sharers have implemented `+ (NSString *)username` 
- added SHKUploadsViewController. It keeps a track of uploads progress + you can cancel uploads from there. Only sharers reporting progress are shown (currently Dropbox, YouTube). 

**2.5.3**
- Methods declared in SHKSharer.h intended to be used only by sharer subclasses were moved into SHKSharer_protected.h. **Possible breaking change: if you use your own SHKSharer subclass, import SHKSharer_protected.h in implementation file.**
- You can supply custom SHKActivityIndicator subclass using ```- (Class)SHKActivityIndicatorSubclass``` method in your configurator.  **Possible breaking change: In case you have your own share delegate, make sure it implements, or inherits all new SHKActivityIndicator calls, otherwise indicator might not display, or dismiss well.**
- Dropbox enhancements:
     1. can get userInfo, 
     2. user can pick directory where to save the file or you can pre fill it via ```item.dropboxDestinationDirectory```.
     3. shows upload progress
- TextMessage sharer can accept attachments for iMessage or MMS
- ShareKit can send successful share response included in ```SHKSendDidFinishNotification```'s userInfo. Currently implemented for Dropbox only.
- Facebook-ios-sdk updated to 3.11

**2.5.1**
- Google+ SDK updated to 1.5.0 **Breaking change: you have to add AddressBook.framework**

**2.5.0**
- Native sharing for Google+. This means share sheet is presented within the app, instead of a trip to mobile Safari. As a bonus, image (UIImage or file) and video file share has been added. **There is a breaking change: GTL subproject and Google Plus SDK target have been removed. You have to add Frameworks/GoogleOpenSource.framework to your project instead (also if you use YouTube only). Also add Frameworks/GooglePlus.bundle**
- Enhanced URL share for LinkedIn (you can explicitly set picture and description via item.URLPictureURI and item.URLDescription. Deprecated facebookURLShareDescription and facebookURLSharePictureURI as they were Facebook specific.)
- Flickr can share photo file (thus preserves exif info) and video. No longer needs ObjectiveFlickr submodule.
- Added new configuration option for Flickr `- (NSString *)flickrPermissions`
- LinkedIn can get user info
- iOS Twitter sharer is now fully standalone, can share video and large photos via yfrog, can fetch user info. Everything is handled via SLRequest.
- iOS Facebook can share videos, fetch user info via SLRequest. In case you remove SHKFacebook, there is no need for Facebook-ios-sdk nor app delegates calls and URL scheme in info.plist
- New configuration option ``` - (NSNumber *)useAppleShareUI``` You can choose, if iOS sharers use Apple's UI, or ShareKit's own (potentially customised for your app)
- Convenient ``` [SHKSharer username]``` method so that you can display logged user in your app
