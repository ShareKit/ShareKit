//
//  OAAttachment.h
//  Zeus
//
//  Created by Jamie Pinkham on 2/3/11.
//  Copyright 2011 Tumblr. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OAAttachment : NSObject {
	NSString *name;
	NSString *fileName;
	NSString *contentType;
	NSData *data;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *contentType;
@property (nonatomic, copy) NSData *data;

- (id)initWithName:(NSString *)aName filename:(NSString *)aFilename contentType:(NSString *)aContentType data:(NSData *)aData;

@end
