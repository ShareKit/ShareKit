//
//  LiveDownloadOperationListener.h
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
