//
//  NSMutableDictionary+NSNullsToEmptyStrings.h
//  ShareKit
//
//  Created by Vilem Kurz on 23.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (NSNullsToEmptyStrings)

- (void)convertNSNullsToEmptyStrings;

@end
