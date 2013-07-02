//
//  SHKiOSFacebook.m
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOSFacebook.h"
#import "SHKiOSSharer_Protected.h"
#import "SharersCommonHeaders.h"

@implementation SHKiOSFacebook

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Facebook");
}

+ (NSString *)sharerId
{
	return @"SHKFacebook";
}

- (void)share {
    
    [self shareWithServiceType:SLServiceTypeFacebook];
}


@end