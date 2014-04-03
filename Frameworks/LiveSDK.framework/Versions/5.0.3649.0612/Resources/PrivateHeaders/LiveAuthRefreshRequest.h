//
//  LiveAuthRefreshRequest.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
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

@end
