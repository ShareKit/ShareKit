//
//  SHKGooglePlus.m
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

#import "SHKGooglePlus.h"
#import "SHKiOSSharer_Protected.h"

@interface SHKGooglePlus ()

@end

@implementation SHKGooglePlus

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Google Plus";
}

+ (NSString *)sharerId
{
	return @"SHKGooglePlus";
}

+ (BOOL)canShareURL
{
    return YES;
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)canShareText
{
    return YES;
}

+ (BOOL)canShare
{
    return YES;
}

- (NSUInteger)maxTextLength {
    
    return 280;
}

- (void)share {
    
    
}

- (NSString *)joinedTags {
    
    NSString *result = [self tagStringJoinedBy:@" " allowedCharacters:nil tagPrefix:@"#" tagSuffix:@"#"];
    return result;
}

@end
