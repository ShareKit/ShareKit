//
//  NSMutableDictionary+NSNullsToEmptyStrings.m
//  ShareKit
//
//  Created by Vilem Kurz on 23.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

@implementation NSMutableDictionary (NSNullsToEmptyStrings)

- (void)convertNSNullsToEmptyStrings {
    
    NSArray *responseObjectKeys = [self allKeys];
    
    for (NSString *key in responseObjectKeys) {
        
        id object = [self objectForKey:key];        
        if (object == [NSNull null]) {
            [self setObject:@"" forKey:key];
        }
        else if ([object isKindOfClass:[NSDictionary class]]) {
            [object convertNSNullsToEmptyStrings];
        }
    }
}

@end
