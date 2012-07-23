//
//  DBRestClient+Photos.h
//  DropboxSDK
//
//  Created by Brian Smith on 6/11/12.
//  Copyright (c) 2012 Dropbox, Inc. All rights reserved.
//

#import "DBRestClient.h"

@interface DBRestClient (Photos)

- (void)loadCuDelta:(NSString *)cursor;

@end


@protocol DBRestClientPhotosDelegate <DBRestClientDelegate>

- (void)restClient:(DBRestClient*)client loadedCuDeltaEntries:(NSArray *)entries reset:(BOOL)shouldReset cursor:(NSString *)cursor hasMore:(BOOL)hasMore;
- (void)restClient:(DBRestClient*)client loadCuDeltaFailedWithError:(NSError *)error;

@end