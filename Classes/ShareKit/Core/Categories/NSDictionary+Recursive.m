//
//  NSDictionary+Recursive.m
//  ShareKit
//
//  Created by Vilem Kurz on 03/12/2013.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSDictionary+Recursive.h"

#import "Debug.h"

@implementation NSDictionary (Recursive)

//must be class method to be able to pass nested dictionary into the block.
+ (void)recursivelyEnumerateDictionary:(NSDictionary *)dictToEnumerate usingBlock:(void (^)(NSDictionary *dict, id key, id obj, BOOL *stop))block {
    
    NSArray *keys = [dictToEnumerate allKeys];
    __block BOOL stop = NO;
    
    for (NSString *key in keys) {
        
        id object = [dictToEnumerate objectForKey:key];
        if ([object isKindOfClass:[NSDictionary class]]) {
            block(dictToEnumerate, key, object, &stop);
            if (stop) return;
            [NSDictionary recursivelyEnumerateDictionary:object usingBlock:block];
        } else {
            block(dictToEnumerate, key, object, &stop);
        }
        
        if (stop) return;
    }
}

- (id)findRecursivelyValueForKey:(NSString *)searchedKey {
    
    __block NSString *result = nil;
    
    [NSDictionary recursivelyEnumerateDictionary:self usingBlock:^(NSDictionary *dict, id key, id obj, BOOL *stop) {
        if ([key isEqualToString:searchedKey]) {
            result = obj;
            *stop = YES;
        }
    }];
    
    return result;
}

@end
