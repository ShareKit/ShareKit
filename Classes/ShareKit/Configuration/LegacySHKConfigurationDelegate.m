//
//  DefaultSHKConfiguration.m
//  ShareKit
//
//  Created by Edward Dale on 16.10.10.
//  Copyright 2010 RIT. All rights reserved.
//

#import "LegacySHKConfigurationDelegate.h"
#import "SHKConfig.h"

@implementation LegacySHKConfigurationDelegate

- (id)init
{
    if ((self = [super init])) {
		configuration = [[NSDictionary alloc] initWithObjectsAndKeys:
						 SHKMyAppName, @"appName", 
						 SHKMyAppURL, @"appURL", 
						 SHKDeliciousConsumerKey, @"deliciousConsumerKey", 
						 SHKDeliciousSecretKey, @"deliciousSecretKey", 
						 [NSNumber numberWithBool:SHKFacebookUseSessionProxy], @"facebookUseSessionProxy", 
						 SHKFacebookKey, @"facebookKey", 
						 SHKFacebookSecret, @"facebookSecret", 
						 SHKFacebookSessionProxyURL, @"facebookSessionProxyURL", 
						 SHKReadItLaterKey, @"readItLaterKey", 
						 SHKTwitterConsumerKey, @"twitterConsumerKey", 
						 SHKTwitterSecret, @"twitterSecret", 
						 SHKTwitterCallbackUrl, @"twitterCallbackUrl", 
						 [NSNumber numberWithInt:SHKTwitterUseXAuth], @"twitterUseXAuth", 
						 SHKTwitterUsername, @"twitterUsername", 
						 SHKBitLyLogin, @"bitLyLogin", 
						 SHKBitLyKey, @"bitLyKey", 
						 [NSNumber numberWithInt:SHKShareMenuAlphabeticalOrder], @"shareMenuAlphabeticalOrder", 
						 [NSNumber numberWithInt:SHKSharedWithSignature], @"sharedWithSignature", 
						 SHKBarStyle, @"barStyle", 
						 [NSNumber numberWithInt:SHKBarTintColorRed], @"barTintColorRed", 
						 [NSNumber numberWithInt:SHKBarTintColorGreen], @"barTintColorGreen", 
						 [NSNumber numberWithInt:SHKBarTintColorBlue], @"barTintColorBlue", 
						 [NSNumber numberWithInt:SHKFormFontColorRed], @"formFontColorRed", 
						 [NSNumber numberWithInt:SHKFormFontColorGreen], @"formFontColorGreen", 
						 [NSNumber numberWithInt:SHKFormFontColorBlue], @"formFontColorBlue", 
						 [NSNumber numberWithInt:SHKFormBgColorRed], @"formBgColorRed", 
						 [NSNumber numberWithInt:SHKFormBgColorGreen], @"formBgColorGreen", 
						 [NSNumber numberWithInt:SHKFormBgColorBlue], @"formBgColorBlue", 
						 SHKModalPresentationStyle, @"modalPresentationStyle", 
						 SHKModalTransitionStyle, @"modalTransitionStyle", 
						 SHKDebugShowLogs, @"debugShowLogs", 
						 [NSNumber numberWithInt:SHK_MAX_FAV_COUNT], @"maxFavCount", 
						 SHK_FAVS_PREFIX_KEY, @"favsPrefixKey", 
						 SHK_AUTH_PREFIX, @"authPrefix", 
						 nil];
	}
	
	NSLog(@"Default configuration: %@", configuration);
    return self;	
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return [super respondsToSelector:aSelector] || [configuration objectForKey:NSStringFromSelector(aSelector)] != nil;
}

- (id) performSelector:(SEL)aSelector
{
	id configValue = [configuration objectForKey:NSStringFromSelector(aSelector)];
	if(configValue == nil) {
		return [super performSelector:aSelector];
	} else {
		return configValue;
	}
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	NSString *configValue = [configuration objectForKey:NSStringFromSelector([anInvocation selector])];
	if(configValue == nil) {
		[super forwardInvocation:anInvocation];
	} else {
		[anInvocation setReturnValue:configValue];
	}
}
@end
