//
//  LiveDownloadOperationListener.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LiveDownloadOperation;
@class LiveOperationProgress;

// LiveDownloadOperationDelegate represents the protocol capturing SkyDrive download operation related callback 
// handling methods.
@protocol LiveDownloadOperationDelegate <NSObject>

// This is invoked when the operation was successful.
- (void) liveOperationSucceeded:(LiveDownloadOperation *)operation;

@optional
// This is invoked when the operation failed.
- (void) liveOperationFailed:(NSError *)error
                  operation:(LiveDownloadOperation *)operation;

// This is invoked when there is a download progress event raised.
- (void) liveDownloadOperationProgressed:(LiveOperationProgress *)progress
                                    data:(NSData *)receivedData
                               operation:(LiveDownloadOperation *)operation;



@end
