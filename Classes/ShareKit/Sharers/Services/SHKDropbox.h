//
//  SHKDropbox.h
//  ShareKit
//
//  Created by Orifjon Meliboyev on 12/07/23.
//  Copyright (c) 2012 SSD. All rights reserved.
//

#import "SHKOAuthSharer.h"
#import "SHK.h"
#import <DropboxSDK/DropboxSDK.h>

static NSString *const kSHKDropboxUserId=@"kSHKDropboxUserId";
static NSString *const kSHKDropboxAccessTokenKey=@"kSHKDropboxAccessToken";
static NSString *const kSHKDropboxExpiryDateKey=@"kSHKDropboxExpiryDate";


@interface SHKDropbox : SHKOAuthSharer <DBSessionDelegate>

@end
