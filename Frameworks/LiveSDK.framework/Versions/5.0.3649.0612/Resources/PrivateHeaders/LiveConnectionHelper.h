//
//  LiveConnectionHelper.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveConnectionCreatorDelegate.h"

@interface LiveConnectionHelper : NSObject

+ (id) createConnectionWithRequest:(NSURLRequest *)request
                          delegate:(id)delegate;

+ (void) setLiveConnectCreator:(id<LiveConnectionCreatorDelegate>)creator;

@end
