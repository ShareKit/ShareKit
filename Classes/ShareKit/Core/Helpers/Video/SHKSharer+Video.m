//
//  SHKSharer+Video.m
//  ShareKit
//
//  Created by Jacob Dunn on 2/28/13.
//
//

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SHKSharer+Video.h"
#import <AVFoundation/AVFoundation.h>

@implementation SHKSharer (Video)

-(BOOL)isOfValidTypes:(NSArray *)validTypes
{
    if (item.file == nil) return YES;
    if(![validTypes containsObject:item.file.filename.pathExtension]) return NO;
    return YES;
}

-(BOOL)isUnderDuration:(NSInteger)maxDuration
{
    if (item.file == nil) return YES;
    
    NSUInteger duration = item.file.duration;
    
    SHKLog(@"checking file duration [%lu] < [%i]",(unsigned long)duration,maxDuration);
    
    return (duration <= maxDuration && duration > 0);
}

-(BOOL)isUnderSize:(NSInteger)maxSize
{
    if (item.file == nil) return YES;
    
    NSUInteger fileSize = item.file.size;
    
    SHKLog(@"checking file size [%lu] < [%i]",(unsigned long)fileSize,maxSize);
    
    return (fileSize <= maxSize);
}

@end
