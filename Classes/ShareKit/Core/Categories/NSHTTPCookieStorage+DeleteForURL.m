//
//  NSHTTPCookieStorage+DeleteForURL.m
//  ShareKit
//
//  Created by Vilem Kurz on 22.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "NSHTTPCookieStorage+DeleteForURL.h"

@implementation NSHTTPCookieStorage (DeleteForURL)

+ (void)deleteCookiesForURL:(NSURL *)url {
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [storage cookiesForURL:url];
    for (NSHTTPCookie *each in cookies) 
    {
        [storage deleteCookie:each];
    }
}

@end
