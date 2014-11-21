//
//  LiveOperationCore.h
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
#import "LiveAuthDelegate.h"
#import "LiveOperationDelegate.h"
#import "StreamReader.h"

@class LiveConnectClientCore;
@class LiveOperation;

@interface LiveOperationCore : NSObject <StreamReaderDelegate, LiveAuthDelegate>

@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSString *method;
@property (nonatomic, retain) NSData *requestBody;
@property (nonatomic, readonly) id userState; 
@property (nonatomic, assign) id delegate;
@property (nonatomic, readonly) LiveConnectClientCore *liveClient;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, readonly) NSURL *requestUrl;
@property (nonatomic, retain) StreamReader *streamReader;
@property (nonatomic, retain) NSMutableURLRequest *request; 

@property (nonatomic) BOOL completed;
@property (nonatomic, retain) NSString *rawResult;
@property (nonatomic, retain) NSDictionary *result;
@property (nonatomic, retain) id connection;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) id publicOperation;
@property (nonatomic, retain) NSHTTPURLResponse *httpResponse;
@property (nonatomic, retain) NSError *httpError;

- (id) initWithMethod:(NSString *)method
                 path:(NSString *)path
          requestBody:(NSData *)requestBody
             delegate:(id)delegate
            userState:(id)userState
           liveClient:(LiveConnectClientCore *)liveClient;

- (id) initWithMethod:(NSString *)method
                 path:(NSString *)path
          inputStream:(NSInputStream *)inputStream
             delegate:(id)delegate
            userState:(id)userState
           liveClient:(LiveConnectClientCore *)liveClient;

- (void) execute;

- (void) cancel;

- (void) dismissCurrentRequest;

- (void) setRequestContentType;

- (void) sendRequest;

- (void) operationFailed:(NSError *)error;

- (void) operationCompleted;

- (void) operationReceivedData:(NSData *)data;

@end
