//
//  LiveOperationProgress.h
//  Live SDK for iOS
//
//  Copyright 2014 Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
