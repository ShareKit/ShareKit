//
//  LiveOperationInternal.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveOperation.h"
#import "LiveOperationCore.h"

@interface LiveOperation() 

- (id) initWithOpCore:(LiveOperationCore *)opCore;

@property (nonatomic, readonly) LiveOperationCore *liveOpCore;

@end
