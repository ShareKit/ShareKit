//
//  LiveAuthStorage.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
   A utility class to handle auth information persistency.
 */
@interface LiveAuthStorage : NSObject
{
@private
    NSString *_filePath;
    NSString *_clientId;
}

@property (nonatomic, retain) NSString *refreshToken;

- (id) initWithClientId:(NSString *)clientId;

@end
