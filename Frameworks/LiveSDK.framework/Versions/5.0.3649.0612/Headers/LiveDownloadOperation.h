//
//  LiveDownloadOperation.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveDownloadOperationDelegate.h"
#import "LiveOperation.h"

// LiveDownloadOperation class represents an operation of downloading a file from the user's SkyDrive account.
@interface LiveDownloadOperation : LiveOperation

// The NSData instance that contains the downloaded data.
@property (nonatomic, readonly) NSData *data;

@end
