//
//  NSHTTPCookieStorage+DeleteForURL.h
//  ShareKit
//
//  Created by Vilem Kurz on 22.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSHTTPCookieStorage (DeleteForURL)

+ (void)deleteCookiesForURL:(NSURL *)url;

@end
