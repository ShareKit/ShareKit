//
//  LiveConnectSessionStatus.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

// An enum type representing the user's session status.
typedef enum 
{
    // The user is unknown.
    LiveAuthUnknown = 0,
    
    // The user has consented to the scopes the app specified.
    LiveAuthConnected = 1,
    
    // The user has not consented to the scopes the app specified yet
    LiveAuthNotConnected = 2,
    
} LiveConnectSessionStatus;
