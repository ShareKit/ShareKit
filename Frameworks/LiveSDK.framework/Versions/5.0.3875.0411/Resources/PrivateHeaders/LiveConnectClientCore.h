//
//  LiveConnectClientCore.h
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
#import "LiveAuthRequest.h"
#import "LiveAuthRefreshRequest.h"
#import "LiveAuthStorage.h"
#import "LiveConnectSession.h"
#import "LiveConstants.h"
#import "LiveDownloadOperationCore.h"
#import "LiveDownloadOperationDelegate.h"
#import "LiveOperationCore.h"
#import "LiveOperationDelegate.h"
#import "LiveUploadOperationDelegate.h"
#import "LiveUploadOverwriteOption.h"

@class LiveAuthRefreshRequest;

@interface LiveConnectClientCore : NSObject 
{
@private
    LiveAuthStorage *_storage;
}

@property (nonatomic, readonly) NSString *clientId;
@property (nonatomic, readonly) NSArray *scopes;

@property (nonatomic) LiveConnectSessionStatus status;
@property (nonatomic, retain) LiveConnectSession *session;

@property (nonatomic, retain) LiveAuthRequest *authRequest;
@property (nonatomic, retain) LiveAuthRefreshRequest *authRefreshRequest;
@property (nonatomic, readonly) BOOL hasPendingUIRequest;

- (id) initWithClientId:(NSString *)clientId
                 scopes:(NSArray *)scopes
               delegate:(id<LiveAuthDelegate>)delegate
              userState:(id)userState;

- (void) login:(UIViewController *)currentViewController
        scopes:(NSArray *)scopes
      delegate:(id<LiveAuthDelegate>)delegate
     userState:(id)userState;

- (void) logoutWithDelegate:(id<LiveAuthDelegate>)delegate
                  userState:(id)userState;

- (void) refreshSessionWithDelegate:(id<LiveAuthDelegate>)delegate
                          userState:(id)userState;

- (LiveOperation *) sendRequestWithMethod:(NSString *)method
                                     path:(NSString *)path
                                 jsonBody:(NSString *)jsonBody
                                 delegate:(id <LiveOperationDelegate>)delegate
                                userState:(id) userState;

- (LiveDownloadOperation *) downloadFromPath:(NSString *)path
                                    delegate:(id <LiveDownloadOperationDelegate>)delegate
                                   userState:(id)userState;

- (LiveOperation *) uploadToPath:(NSString *)path
                        fileName:(NSString *)fileName
                            data:(NSData *)data
                       overwrite:(LiveUploadOverwriteOption)overwrite
                        delegate:(id <LiveUploadOperationDelegate>)delegate
                       userState:(id)userState;

- (LiveOperation *) uploadToPath:(NSString *)path
                        fileName:(NSString *)fileName
                     inputStream:(NSInputStream *)inputStream
                       overwrite:(LiveUploadOverwriteOption)overwrite
                        delegate:(id <LiveUploadOperationDelegate>)delegate
                       userState:(id)userState;

- (void) sendAuthCompletedMessage:(NSArray *)eventArgs;
@end
