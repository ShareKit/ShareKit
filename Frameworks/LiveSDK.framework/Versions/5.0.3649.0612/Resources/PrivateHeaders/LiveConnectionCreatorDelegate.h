//
//  LiveConnectionCreatorDelegate.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LiveConnectionCreatorDelegate <NSObject>

- (id) createConnectionWithRequest:(NSURLRequest *)request
                          delegate:(id)delegate;
@end
