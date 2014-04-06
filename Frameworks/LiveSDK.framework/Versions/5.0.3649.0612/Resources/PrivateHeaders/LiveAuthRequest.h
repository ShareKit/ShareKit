//
//  LiveAuthRequest.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveAuthDelegate.h"
#import "LiveAuthDialog.h"
#import "LiveAuthDialogDelegate.h"
#import "LiveConnectSession.h"

@class LiveConnectClientCore;

// An enum type representing the user's session status.
typedef enum 
{
    AuthNotStarted  = 0,
    AuthAuthorized = 1,
    AuthRefreshToken = 2,
    AuthTokenRetrieved = 3,
    AuthFailed = 4,
    AuthCompleted = 5
    
} LiveAuthRequstStatus;

// Represents a Live service authorization request that handes
// 1) Ask the user to authorize the app for specific scopes.
// 2) Get access token with refresh token.
@interface LiveAuthRequest : NSObject<LiveAuthDialogDelegate>
{
@private 
    LiveConnectClientCore *_client;
    NSArray *_scopes;
    id<LiveAuthDelegate>_delegate;
    id _userState;
    
} 

@property (nonatomic, readonly) BOOL isUserInvolved;
@property (nonatomic, retain) NSString *authCode;
@property (nonatomic, retain) LiveConnectSession *session;
@property (nonatomic, retain) UIViewController *currentViewController;
@property (nonatomic, retain) LiveAuthDialog *authViewController;
@property (nonatomic) LiveAuthRequstStatus status;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) id tokenConnection;
@property (nonatomic, retain) NSMutableData *tokenResponseData;

- (id) initWithClient:(LiveConnectClientCore *)client
               scopes:(NSArray *)scopes
currentViewController:(UIViewController *)currentViewController
             delegate:(id<LiveAuthDelegate>)delegate
            userState:(id)userState;
                
- (void)execute;
- (void)process;
- (void)authorize;
- (void)retrieveToken;
- (void)complete;

@end
