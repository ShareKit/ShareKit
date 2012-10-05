//
//  SHKDropbox.h
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKSharer.h"
#import "DropboxSDK.h"

@interface SHKDropbox : SHKSharer <DBSessionDelegate, DBNetworkRequestDelegate, DBRestClientDelegate, UIAlertViewDelegate>

+ (BOOL)handleOpenURL:(NSURL*)url;

@end
