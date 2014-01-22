//
//  SHKDropbox.h
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKSharer.h"

#ifdef COCOAPODS
#import "DropboxSDK.h"
#else
#import <DropboxSDK/DropboxSDK.h>
#endif

#import "SHKFormOptionController.h"

//
//you could use customValue in SHK item to setup remote path to upload file
static NSString *const kSHKDropboxDestinationDir __attribute__((deprecated ("use dropboxDestinationDirectory property of SHKItem instead. The value is available through [notification.object progress]"))) = @"SHKDropboxDestinationDir";
//the key uses to send notifications with NSNotificationCenter
static NSString *const kSHKDropboxUploadProgress __attribute__((deprecated ("use SHKSendProgressNotification instead."))) =@"SHKDropboxUploadProgress";
static NSString *const kSHKDropboxSharableLink __attribute__((deprecated ("use userInfo payload of SHKSendDidFinishNotification instead"))) = @"SHKDropboxSharableLink"; 

@interface SHKDropbox : SHKSharer <DBNetworkRequestDelegate, DBRestClientDelegate, UIAlertViewDelegate, SHKFormOptionControllerOptionProvider>

+ (BOOL)handleOpenURL:(NSURL*)url;

@end
