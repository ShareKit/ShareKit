//
//  LiveUploadOperationCore.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveOperationCore.h"
#import "LiveUploadOperationDelegate.h"
#import "LiveUploadOverwriteOption.h"

@interface LiveUploadOperationCore : LiveOperationCore <LiveOperationDelegate>
{
@private
    NSString *_fileName;
    LiveOperation *_queryUploadLocationOp;
    NSString *_uploadPath;
    LiveUploadOverwriteOption _overwrite;
}

- (id) initWithPath:(NSString *)path
           fileName:(NSString *)fileName
               data:(NSData *)data
          overwrite:(LiveUploadOverwriteOption)overwrite
           delegate:(id <LiveUploadOperationDelegate>)delegate
          userState:(id)userState
         liveClient:(LiveConnectClientCore *)liveClient;

- (id) initWithPath:(NSString *)path
           fileName:(NSString *)fileName
        inputStream:(NSInputStream *)inputStream
          overwrite:(LiveUploadOverwriteOption)overwrite
           delegate:(id <LiveUploadOperationDelegate>)delegate
          userState:(id)userState
         liveClient:(LiveConnectClientCore *)liveClient;

@end
