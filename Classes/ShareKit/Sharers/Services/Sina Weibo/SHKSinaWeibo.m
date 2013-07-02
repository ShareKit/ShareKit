//
//  SHKSinaWeibo.m
//  ShareKit
//
//  Created by Vilém Kurz on 11/18/12.
//
//

#import "SHKSinaWeibo.h"
#import "SHKiOSSharer_Protected.h"
#import "SharersCommonHeaders.h"

@interface SHKSinaWeibo ()

@end

@implementation SHKSinaWeibo

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Sina Weibo");
}

+ (NSString *)sharerId
{
	return @"SHKSinaWeibo";
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
