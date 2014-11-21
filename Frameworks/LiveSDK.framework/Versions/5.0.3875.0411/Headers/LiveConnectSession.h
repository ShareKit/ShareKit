//
//  LiveConnectSession.h
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

// LiveConnectSession class represents a user's authentication session object that includes
// access token, authentication token, refresh token, session scope values and expires time.
@interface LiveConnectSession : NSObject

- (id) initWithAccessToken:(NSString *)accessToken
       authenticationToken:(NSString *)authenticationToken
              refreshToken:(NSString *)refreshToken
                    scopes:(NSArray *)scopes
                   expires:(NSDate *)expires;

// The access token that is used when consuming Live Services REST API.
@property (nonatomic, readonly) NSString *accessToken;

// The authentication token that can be used to validate user.
@property (nonatomic, readonly) NSString *authenticationToken;

// The refresh token that can be used to retrieve user's access token.
@property (nonatomic, readonly) NSString *refreshToken;

// A list of scopes for the current session.
@property (nonatomic, readonly) NSArray *scopes;

// An NSDate instance indicating when the session expires.
@property (nonatomic, readonly) NSDate *expires;

@end