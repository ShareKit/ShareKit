//
//  LiveAuthDelegate.h
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
#import "LiveConnectSession.h"
#import "LiveConnectSessionStatus.h"

// LiveAuthDelegate represents the protocol capturing authentication related callback handling 
// methods, which includes methods to be invoked when an authentication process is completed
// or failed.
// A delegate that implements the protocol should be passed in as parameter when an app invokes 
// init*, login* and logout* methods on an instance of LiveConnectClient class. 
@protocol LiveAuthDelegate <NSObject>

// This is invoked when the original method call is considered successful.
- (void) authCompleted: (LiveConnectSessionStatus) status
               session: (LiveConnectSession *) session
             userState: (id) userState;

@optional
// This is invoked when the original method call fails.
- (void) authFailed: (NSError *) error
          userState: (id)userState;

@end