//
//  SHKConfiguration.h
//  ShareKit
//
//  Created by Edward Dale on 10/16/10.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import <Foundation/Foundation.h>

@protocol SHKConfigurationDelegate <NSObject>

@optional

- (NSString*)appName;
- (NSString*)appURL;
- (NSString*)deliciousConsumerKey;
- (NSString*)deliciousSecretKey;
- (NSString*)facebookAppId;
- (NSString*)readItLaterKey;
- (NSString*)twitterConsumerKey;
- (NSString*)twitterSecret;
- (NSString*)twitterCallbackUrl;
- (NSNumber*)twitterUseXAuth;
- (NSString*)twitterUsername;
- (NSString*)evernoteUserStoreURL;
- (NSString*)evernoteNetStoreURLBase;
- (NSString*)evernoteConsumerKey;
- (NSString*)evernoteSecret;
- (NSString*)bitLyLogin;
- (NSString*)bitLyKey;
- (NSString*)foursquareV2ClientId;
- (NSString*)foursquareV2RedirectURI;
- (NSString*)linkedInConsumerKey;
- (NSString*)linkedInSecret;
- (NSString*)linkedInCallbackUrl;
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
- (NSString*)sharersPlistName;

// Advanced Configuration
- (NSNumber*)maxFavCount;
- (NSString*)favsPrefixKey;
- (NSString*)authPrefix;
- (NSNumber*)allowOffline;
- (NSNumber*)allowAutoShare;
- (NSNumber*)usePlaceholders;


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
