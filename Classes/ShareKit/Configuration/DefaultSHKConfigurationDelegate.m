//
//  DefaultSHKConfigurationDelegate.m
//  ShareKit
//
//  Created by Edward Dale on 16.10.10.
//  Copyright 2010 RIT. All rights reserved.
//

#import "DefaultSHKConfigurationDelegate.h"


@implementation DefaultSHKConfigurationDelegate

- (NSString*)appName {
	return @"My App Name";
}

- (NSString*)appURL {
	return @"http://example.com";
}

- (NSString*)deliciousConsumerKey {
	return @"";
}

- (NSString*)deliciousSecretKey {
	return @"";
}

- (NSNumber*)facebookUseSessionProxy {
	return [NSNumber numberWithInt:0];
}

- (NSString*)facebookKey {
	return @"";
}

- (NSString*)facebookSecret {
	return @"";
}

- (NSString*)facebookSessionProxyURL {
	return @"";
}

- (NSString*)readItLaterKey {
	return @"";
}

- (NSString*)twitterConsumerKey {
	return @"";
}

- (NSString*)twitterSecret {
	return @"";
}

- (NSString*)twitterCallbackUrl {
	return @"";
}

- (NSNumber*)twitterUseXAuth {
	return [NSNumber numberWithInt:0];
}

- (NSString*)twitterUsername {
	return @"";
}

- (NSString*)bitLyLogin {
	return @"";
}

- (NSString*)bitLyKey {
	return @"";
}

- (NSNumber*)shareMenuAlphabeticalOrder {
	return [NSNumber numberWithInt:0];
}

- (NSNumber*)sharedWithSignature {
	return [NSNumber numberWithInt:0];
}

- (NSString*)barStyle {
	return @"UIBarStyleDefault";
}

- (NSNumber*)barTintColorRed {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)barTintColorGreen {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)barTintColorBlue {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)formFontColorRed {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)formFontColorGreen {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)formFontColorBlue {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)formBgColorRed {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)formBgColorGreen {
	return [NSNumber numberWithInt:-1];
}

- (NSNumber*)formBgColorBlue {
	return [NSNumber numberWithInt:-1];
}

- (NSString*)modalPresentationStyle {
	return @"UIModalPresentationFormSheet";
}

- (NSString*)modalTransitionStyle {
	return @"UIModalTransitionStyleCoverVertical";
}

- (NSNumber*)maxFavCount {
	return [NSNumber numberWithInt:3];
}

- (NSString*)favsPrefixKey {
	return @"SHK_FAVS_";
}

- (NSString*)authPrefix {
	return @"SHK_AUTH_";
}

@end
