//
//  LiveOperationProgress.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

// LiveOperationProgress class represents an operation progress object that encapsulates the progress information 
// of a running operation.
@interface LiveOperationProgress : NSObject

- (id) initWithBytesTransferred:(NSUInteger)bytesTransferred
                     totalBytes:(NSUInteger)totalBytes;

// Number of bytes already transferred.
@property (nonatomic, readonly) NSUInteger bytesTransferred;

// Total bytes to transfer.
@property (nonatomic, readonly) NSUInteger totalBytes;

// Percentage rate of already transferred bytes.
@property (nonatomic, readonly) double progressPercentage;

@end
