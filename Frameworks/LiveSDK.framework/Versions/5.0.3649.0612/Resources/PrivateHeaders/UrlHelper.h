//
//  UrlHelper.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UrlHelper : NSObject

+ (NSString *) encodeUrlParameters: (NSDictionary *)params;
+ (NSDictionary *) decodeUrlParameters: (NSString *)paramStr;

+ (NSURL *) constructUrl: (NSString *)baseUrl params: (NSDictionary *)params;
+ (NSDictionary *) parseUrl:(NSURL *)url ;

+ (BOOL) isFullUrl:(NSString *)url;

+ (NSString *) getQueryString: (NSString *)path;
+ (NSString *) appendQueryString: (NSString *)query toPath: (NSString *)path;

@end
