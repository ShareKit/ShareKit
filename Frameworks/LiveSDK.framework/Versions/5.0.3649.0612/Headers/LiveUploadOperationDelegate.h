//
//  LiveUploadOperationDelegate.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveOperationProgress.h"

// LiveUploadOperationDelegate represents the protocol capturing SkyDrive upload operation related callback 
// handling methods.
@protocol LiveUploadOperationDelegate <NSObject>

// This is invoked when the operation was successful.
- (void) liveOperationSucceeded:(LiveOperation *)operation;

@optional
// This is invoked when the operation failed.
- (void) liveOperationFailed:(NSError *)error
                   operation:(LiveOperation *)operation;

// This is invoked when there is a upload progress event raised.
- (void) liveUploadOperationProgressed:(LiveOperationProgress *)progress
                             operation:(LiveOperation *)operation;

@end
