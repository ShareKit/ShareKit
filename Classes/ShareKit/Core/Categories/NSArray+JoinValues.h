//
//  NSArray+JoinValues.h
//  ShareKit
//
//  Created by Vilém Kurz on 7/29/13.
//
//

#import <Foundation/Foundation.h>

@interface NSArray (JoinValues)

- (NSString *)joinValuesForIndexes:(NSIndexSet *)indexes;

@end
