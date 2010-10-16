#import <Foundation/Foundation.h>

@protocol SHKConfigurationDelegate <NSObject>

@optional

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

//- (NSNumber*)SHK_MAX_FAV_COUNT;
//- (NSString*)SHK_FAVS_PREFIX_KEY;
//- (NSString*)SHK_AUTH_PREFIX;
- (NSNumber*)maxFavCount;
- (NSString*)favsPrefixKey;
- (NSString*)authPrefix;

@end

@interface SHKConfiguration : NSObject {
	id <SHKConfigurationDelegate> delegate;
}

@property (nonatomic,readonly) id <SHKConfigurationDelegate> delegate;

+ (SHKConfiguration*)sharedInstance;

+ (SHKConfiguration*)sharedInstanceWithDelegate:(id <SHKConfigurationDelegate>)delegate;

- (id)initWithDelegate:(id <SHKConfigurationDelegate>)delegate;

- (id)configurationValue:(NSString*)selector;

#define SHKCONFIG(_CONFIG_KEY) [[SHKConfiguration sharedInstance] configurationValue:@#_CONFIG_KEY]

@end
