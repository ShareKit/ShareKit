//
//  LiveAuthDialogDelegate.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LiveAuthDialogDelegate <NSObject>

- (void) authDialogCompletedWithResponse:(NSURL *)responseUrl;

- (void) authDialogFailedWithError:(NSError *)error;

- (void) authDialogCanceled;

- (void) authDialogDisappeared;

@end
