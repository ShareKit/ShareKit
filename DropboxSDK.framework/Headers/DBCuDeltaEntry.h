//
//  DBCuDeltaEntry.h
//  DropboxSDK
//
//  Created by Brian Smith on 6/11/12.
//  Copyright (c) 2012 Dropbox, Inc. All rights reserved.
//

#import "DBMetadata.h"

@interface DBCuDeltaEntry : NSObject {
	NSString *lowercasePath;
	DBMetadata *metadata;
	NSString *sortKey;
	NSDate *timeTaken;
	NSString *uniquenessKey;
}

- (id)initWithArray:(NSArray *)array;

@property (nonatomic, readonly) NSString *lowercasePath;
@property (nonatomic, readonly) DBMetadata *metadata;
@property (nonatomic, readonly) NSString *sortKey;
@property (nonatomic, readonly) NSDate *timeTaken;
@property (nonatomic, readonly) NSString *uniquenessKey;

@end
