//
//  SHKSession.h
//  ShareKit
//
//  Created by Vilem Kurz on 25/02/2014.
//
//

/*!
 @class SHKSession
 @discussion Wrapper of NSURLSession. Each sharer can have only one NSURLSession with one task. The main reason for implementing NSURLSession alongside SHKRequest or OAAsynchronousDataFetcher is its ability to report upload progress. So its main use case is to upload large file shares. In other words, use this only if you need progress reported - all SHKSession uploads do report progress. In all other cases use classic SHKRequest or OAMutableURLRequest
 */

#import <Foundation/Foundation.h>

@protocol SHKSessionDelegate;

@interface SHKSession : NSObject <NSURLSessionDelegate>

+ (instancetype)startSessionWithRequest:(NSURLRequest *)request delegate:(id <SHKSessionDelegate>)delegate completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion;

- (void)cancel;

@end