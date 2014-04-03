//
//  LiveOperation.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
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