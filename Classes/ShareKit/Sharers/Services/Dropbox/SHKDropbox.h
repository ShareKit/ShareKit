//
//  SHKDropbox.h
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKSharer.h"
#import "DropboxSDK.h"
//you could use customValue in SHK item to setup remote path to upload file
static NSString *const kSHKDropboxDestinationDir =@"SHKDropboxDestinationDir";
//the key uses to send notifications with NSNotificationCenter
static NSString *const kSHKDropboxUploadProgress =@"SHKDropboxUploadProgress";
static NSString *const kSHKDropboxSharableLink =@"SHKDropboxSharableLink";

@interface SHKDropbox : SHKSharer <DBSessionDelegate, DBNetworkRequestDelegate, DBRestClientDelegate, UIAlertViewDelegate>

+ (BOOL)handleOpenURL:(NSURL*)url;

@end
