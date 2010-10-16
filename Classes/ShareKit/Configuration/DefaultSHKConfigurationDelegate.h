//
//  DefaultSHKConfigurationDelegate.h
//  ShareKit
//
//  Created by Edward Dale on 16.10.10.
//  Copyright 2010 RIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKConfiguration.h"

@interface DefaultSHKConfigurationDelegate : NSObject <SHKConfigurationDelegate> {

}

- (NSString*)appName;
- (NSString*)appURL;
- (NSString*)deliciousConsumerKey;
- (NSString*)deliciousSecretKey;
- (NSNumber*)facebookUseSessionProxy;
- (NSString*)facebookKey;
- (NSString*)facebookSecret;
- (NSString*)facebookSessionProxyURL;
- (NSString*)readItLaterKey;
- (NSString*)twitterConsumerKey;
- (NSString*)twitterSecret;
- (NSString*)twitterCallbackUrl;
- (NSNumber*)twitterUseXAuth;
- (NSString*)twitterUsername;
- (NSString*)bitLyLogin;
- (NSString*)bitLyKey;
- (NSNumber*)shareMenuAlphabeticalOrder;
- (NSNumber*)sharedWithSignature;
- (NSString*)barStyle;
- (NSNumber*)barTintColorRed;
- (NSNumber*)barTintColorGreen;
- (NSNumber*)barTintColorBlue;
- (NSNumber*)formFontColorRed;
- (NSNumber*)formFontColorGreen;
- (NSNumber*)formFontColorBlue;
- (NSNumber*)formBgColorRed;
- (NSNumber*)formBgColorGreen;
- (NSNumber*)formBgColorBlue;
- (NSString*)modalPresentationStyle;
- (NSString*)modalTransitionStyle;
- (NSNumber*)maxFavCount;
- (NSString*)favsPrefixKey;
- (NSString*)authPrefix;

@end
