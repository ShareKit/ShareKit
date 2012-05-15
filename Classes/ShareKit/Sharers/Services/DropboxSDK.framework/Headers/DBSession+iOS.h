//
//  DBSession+iOS.h
//  DropboxSDK
//
//  Created by Brian Smith on 3/7/12.
//  Copyright (c) 2012 Dropbox. All rights reserved.
//

#import "DBSession.h"

@interface DBSession (iOS)

- (void)link;
- (void)linkUserId:(NSString *)userId;

- (BOOL)handleOpenURL:(NSURL *)url;

@end
