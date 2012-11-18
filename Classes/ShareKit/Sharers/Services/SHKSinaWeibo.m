//
//  SHKSinaWeibo.m
//  ShareKit
//
//  Created by Vilém Kurz on 11/18/12.
//
//

#import "SHKSinaWeibo.h"
#import "SHKiOSSharer_Protected.h"

@interface SHKSinaWeibo ()

@end

@implementation SHKSinaWeibo

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Sina Weibo";
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

@end
