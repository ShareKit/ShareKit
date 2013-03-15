//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 17.11.2011.
//  Copyright (c) 2011 Cocoa Miners. All rights reserved.
//

#import "SHKiOSTwitter.h"
#import "SHKiOSSharer_Protected.h"

@implementation SHKiOSTwitter

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Twitter");
}

+ (NSString *)sharerId
{
	return @"SHKTwitter";
}

- (NSUInteger)maxTextLength {
    
    return 140;
}

- (NSString *)joinedTags {
    
    return [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:@"#" tagSuffix:nil];
}

- (void)share {
    
    [self shareWithServiceType:SLServiceTypeTwitter];
}

@end
