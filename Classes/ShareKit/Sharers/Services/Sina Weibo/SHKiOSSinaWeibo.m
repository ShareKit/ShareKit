//
//  SHKiOSSinaWeibo.m
//  ShareKit
//
//  Created by Vilém Kurz on 11/18/12.
//
//

#import "SHKiOSSinaWeibo.h"
#import "SHKiOSSharer_Protected.h"

@interface SHKiOSSinaWeibo ()

@end

@implementation SHKiOSSinaWeibo

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Sina Weibo";
}

+ (NSString *)sharerId
{
	return @"SHKiOSSinaWeibo";
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
	if (NSClassFromString(@"SLComposeViewController")) {
        BOOL result = [SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo];
        return result;
    } else {
        return NO;
    }
}

- (NSUInteger)maxTextLength {
    
    return 280;
}

- (void)share {
    
    [self shareWithServiceType:SLServiceTypeSinaWeibo];
}

- (NSString *)joinedTags {
    
    NSString *result = [self tagStringJoinedBy:@" " allowedCharacters:nil tagPrefix:@"#" tagSuffix:@"#"];
    return result;
}

@end
