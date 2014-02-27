//
//  SHKSessionDelegate.h
//  ShareKit
//
//  Created by Vilem Kurz on 26/02/2014.
//
//

#import <Foundation/Foundation.h>

@protocol SHKSessionDelegate <NSObject>

- (void)showUploadedBytes:(int64_t)uploadedBytes totalBytes:(int64_t)totalBytes;

@end
