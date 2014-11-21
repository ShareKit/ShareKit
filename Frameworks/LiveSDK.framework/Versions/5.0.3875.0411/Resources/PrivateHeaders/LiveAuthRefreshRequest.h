//
//  LiveAuthRefreshRequest.h
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
#import "LiveConnectClientCore.h"

@class LiveConnectClientCore;

@interface LiveAuthRefreshRequest : NSObject
{
@private
    NSString *_clientId;
    NSArray *_scopes;
    NSString *_refreshToken;
    id<LiveAuthDelegate> _delegate;
    id _userState;
    LiveConnectClientCore *_client;
}

@property (nonatomic, retain) id tokenConnection;
@property (nonatomic, retain) NSMutableData *tokenResponseData;

- (id) initWithClientId:(NSString *)clientId
                  scope:(NSArray *)scopes
           refreshToken:(NSString *)refreshToken
               delegate:(id<LiveAuthDelegate>)delegate
              userState:(id)userState
             clientStub:(LiveConnectClientCore *)client;

- (void) execute;

- (void) cancel;

@end
