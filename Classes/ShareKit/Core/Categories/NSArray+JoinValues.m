//
//  NSArray+JoinValues.m
//  ShareKit
//
//  Created by Vilém Kurz on 7/29/13.
//
//

#import "NSArray+JoinValues.h"

@implementation NSArray (JoinValues)

- (NSString *)joinValuesForIndexes:(NSIndexSet *)indexes
{
	if ([indexes count] < 1) return nil;
    
    __block NSString *resultVal = nil;
	
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
        
        NSString *displayValue = self[index];
        resultVal = resultVal == nil ?  displayValue : [NSString stringWithFormat:@"%@,%@", resultVal, displayValue];
    }];
    
    return resultVal;
}

@end
