//
//  LiveDownloadOperationCore.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveOperationCore.h"
#import "LiveDownloadOperationDelegate.h"

@interface LiveDownloadOperationCore : LiveOperationCore
{
@private
    NSUInteger contentLength;
}

- (id) initWithPath:(NSString *)path
           delegate:(id <LiveDownloadOperationDelegate>)delegate
          userState:(id)userState
         liveClient:(LiveConnectClientCore *)liveClient;

@end
