//
//  LiveOperation.h
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
#import "LiveOperationDelegate.h"

// LiveOperation class represents an operation that sends a request to Live Service REST API.
@interface LiveOperation : NSObject 

// The path of the request.
@property (nonatomic, readonly) NSString *path;

// The method of the request.
@property (nonatomic, readonly) NSString *method;

// The text receieved from the Live Service REST API response.
@property (nonatomic, readonly) NSString *rawResult;

// The parsed result received from the Live Service REST API response
@property (nonatomic, readonly) NSDictionary *result;

// The userState object passed in when the original method was invoked on the LiveConnectClient instance.
@property (nonatomic, readonly) id userState; 

// The delegate instance to handle the operation callbacks.
@property (nonatomic, assign) id delegate;

// Cancel the current operation. 
- (void) cancel;

@end