//
//  LiveOperationDelegate.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class  LiveOperation;

// LiveOperationDelegate represents the protocol capturing Live service access operation related callback 
// handling methods.
@protocol LiveOperationDelegate <NSObject>

// This is invoked when the operation was successful.
- (void) liveOperationSucceeded:(LiveOperation *)operation;

// This is invoked when the operation failed.
@optional
- (void) liveOperationFailed:(NSError *)error
                   operation:(LiveOperation*)operation;

@end
