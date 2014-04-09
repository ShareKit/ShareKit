//
//  LiveAuthDelegate.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
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