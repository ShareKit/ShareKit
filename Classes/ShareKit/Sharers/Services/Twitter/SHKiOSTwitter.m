//
//  SHKiOS5Twitter.m
//  ShareKit
//
//  Created by Vilem Kurz on 17.11.2011.
//  Copyright (c) 2011 Cocoa Miners. All rights reserved.
//

#import "SHKiOSTwitter.h"
#import <Social/Social.h>
#import "SHKiOSSharer_Protected.h"

@implementation SHKiOSTwitter

+ (NSString *)sharerTitle
{
	return @"Twitter";
}

+ (NSString *)sharerId
{
	return @"SHKTwitter";
}

- (void)share {
    
    [self shareWithServiceType:SLServiceTypeTwitter];
}

@end
