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
    if (item.srcVideoPath == nil) return YES;
    if(![validTypes containsObject:item.srcVideoPath.pathExtension]) return NO;
    return YES;
}

-(BOOL)isUnderDuration:(NSInteger)maxDuration
{
    if (item.srcVideoPath == nil) return YES;
    
    //Create an AVAsset from the given URL
    NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:item.srcVideoPath] options:asset_options];
    float duration = CMTimeGetSeconds(avAsset.duration);
    
    SHKLog(@"checking file duration [%f] < [%i]",duration,maxDuration);
    
    return (duration <= maxDuration && duration > 0);
}

-(BOOL)isUnderSize:(NSInteger)maxSize
{
    if (item.srcVideoPath == nil) return YES;
    
    // Get video size
    long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.srcVideoPath error:nil][NSFileSize] longLongValue];
    
    SHKLog(@"checking file size [%lld] < [%i]",fileSize,maxSize);
    
    return (fileSize <= maxSize);
}

@end
