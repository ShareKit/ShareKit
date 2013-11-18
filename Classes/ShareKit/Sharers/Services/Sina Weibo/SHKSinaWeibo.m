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
#import <Accounts/Accounts.h>

@interface SHKSinaWeibo ()

@end

@implementation SHKSinaWeibo

#pragma mark - Configuration : Service Definition

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

#pragma mark SHKiOSSharer config

- (NSString *)accountTypeIdentifier { return ACAccountTypeIdentifierSinaWeibo; }

- (NSString *)joinedTags {
    
    NSString *result = [self tagStringJoinedBy:@" " allowedCharacters:nil tagPrefix:@"#" tagSuffix:@"#"];
    return result;
}

#pragma mark Share

- (void)share {
    
    [self shareWithServiceType:SLServiceTypeSinaWeibo];
}



@end
