//
//  LiveApiHelper.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LiveApiHelper : NSObject

+ (NSURL *) buildAPIUrl:(NSString *)path;

+ (NSURL *) buildAPIUrl:(NSString *)path
                 params:(NSDictionary *)params;

+ (NSString *) buildCopyMoveBody:(NSString *)destination;

+ (NSError *) createAPIError:(NSDictionary *)info;

+ (NSError *) createAPIError:(NSString *)code
                     message:(NSString *)message
                  innerError:(NSError *)error;

+ (NSString *) getXHTTPLiveLibraryHeaderValue;

+ (BOOL) isFilePath: (NSString *)path;

+ (void) parseApiResponse:(NSData *)data
             textResponse:(NSString **)textResponse
                 response:(NSDictionary **)response
                    error:(NSError **)error;

@end
