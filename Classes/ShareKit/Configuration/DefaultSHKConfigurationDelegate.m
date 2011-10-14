//
//  DefaultSHKConfigurationDelegate.m
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

- (NSString*)facebookAppId {
	return @"";
}

- (NSString*)facebookLocalAppId {
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

- (NSString*)evernoteUserStoreURL {
	return @"";
}

- (NSString*)evernoteNetStoreURLBase {
	return @"";
}

- (NSString*)evernoteConsumerKey {
	return @"";
}

- (NSString*)evernoteSecret {
	return @"";
}

- (NSString*)foursquareV2ClientId {
    return @"";
}

- (NSString*)foursquareV2RedirectURI {
    return @"";
}

- (NSString*)bitLyLogin {
	return @"";
}

- (NSString*)bitLyKey {
	return @"";
}

- (NSString*)linkedInConsumerKey {
	return @"";
}

- (NSString*)linkedInSecret {
	return @"";
}

- (NSString*)linkedInCallbackUrl {
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

- (NSString*)sharersPlistName {
	return @"SHKSharers.plist";
}

- (NSNumber*)allowOffline {
	return [NSNumber numberWithBool:true];
}

- (NSNumber*)allowAutoShare {
	return [NSNumber numberWithBool:true];
}

- (NSNumber*)usePlaceholders {
	return [NSNumber numberWithBool:false];
}

@end
