//
//  ShareKitDemoConfigurator.m
//  ShareKit
//
//  Created by Vilem Kurz on 12.11.2011.
//  Copyright (c) 2011 Cocoa Miners. All rights reserved.
//

/*** For more information about particular setting see comments in DefaultSHKConfigurator.m ***/

#import "ShareKitDemoConfigurator.h"

@implementation ShareKitDemoConfigurator


#pragma mark - App Description

- (NSString*)appName {
	return @"Share Kit Demo App";
}

- (NSString*)appURL {
	return @"https://github.com/ShareKit/ShareKit/";
}

# pragma mark - API Keys

/*** DO NOT USE THESE CLIENT ID'S IN YOUR APP! You should get your own from particular service's URL!!!! Otherwise you may cause problems to maintainers of ShareKit ***/

- (NSString*)onenoteClientId {
    return @"000000004C10E500"; // DO NOT USE THIS CLIENT ID IN YOUR APP! You should get your own from above URL!!!!
}

- (NSString*)vkontakteAppId {
	return @"2706858";
}

- (NSString*)facebookAppId {
	return @"232705466797125";
}

- (NSString*)facebookLocalAppId {
	return @"";
}

- (NSNumber*)forcePreIOS6FacebookPosting {
	return [NSNumber numberWithBool:false];
}

- (NSString*)googlePlusClientId {
    return @"1009915768979.apps.googleusercontent.com";
}

- (NSString *)pocketConsumerKey {
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return @"14225-bdc4f6b29cd76ce0603638e8";
    } else {
        return @"14225-3e2ae99c6fc078de5496577c";
    }
}

-(NSString*)diigoKey {
  return @"f401ddc3546cdf3c";
}

- (NSNumber*)forcePreIOS5TwitterAccess {
    return [NSNumber numberWithBool:false];
}

- (NSString*)twitterConsumerKey {
	return @"48Ii81VO5NtDKIsQDZ3Ggw";
}

- (NSString*)twitterSecret {
	return @"WYc2HSatOQGXlUCsYnuW3UjrlqQj0xvkvvOIsKek32g";
}

- (NSString*)twitterCallbackUrl {
	return @"http://twitter.sharekit.com";
}

- (NSNumber*)twitterUseXAuth {
	return [NSNumber numberWithInt:0];
}

- (NSString*)twitterUsername {
	return @"";
}

- (NSString *)evernoteHost {
    return @"sandbox.evernote.com";
}

- (NSString*)evernoteConsumerKey {
	return @"hansmeyer0711-4037";
}

- (NSString*)evernoteSecret {
	return @"e9d68467cd4c1aeb";
}

- (NSString*)flickrConsumerKey {
    return @"72f05286417fae8da2d7e779f0eb1b2a";
}

- (NSString*)flickrSecretKey {
    return @"b5e731f395031782";
}

- (NSString*)flickrCallbackUrl{
    return @"app://flickr";
}

- (NSString*)bitLyLogin {
	return @"vilem";
}

- (NSString*)bitLyKey {
	return @"R_466f921d62a0789ac6262b7711be8454";
}

- (NSString*)linkedInConsumerKey {
	return @"ppc8a0wlnipp";
}

- (NSString*)linkedInSecret {
	return @"jSzl76tvzsPgKBXh";
}

- (NSString*)linkedInCallbackUrl {
	return @"http://yourdomain.com/callback";
}

- (NSString*)readabilityConsumerKey {
	return @"ctruman";
}

- (NSString*)readabilitySecret {
	return @"RGXDE6wTygKtkwDBHpnjCAyvz2dtrhLD";
}

- (NSNumber*)readabilityUseXAuth {
  return [NSNumber numberWithInt:1];;
}

- (NSString*)foursquareV2ClientId {
    return @"NFJOGLJBI4C4RSZ3DQGR0W4ED5ZWAAE5QO3FW02Z3LLVZCT4";
}

- (NSString*)foursquareV2RedirectURI {
    return @"app://foursquare";
}

- (NSString*)tumblrConsumerKey {
	return @"vT0GPbmG5pwWOLTyrFo6uG0UJQEfX4RgrnXY7ZTzkAJyCrHNPF";
}

- (NSString *)plurkAppKey {
  return @"orexUORVkR2C";
}

- (NSString*)tumblrSecret {
	return @"XsYJPUNJDwCAw6B1PcmFjXuCLtgBp8chRrNuZhpLzn8gFBDg42";
}

- (NSString*)tumblrCallbackUrl {
	return @"tumblr.sharekit.com";
}

- (NSString*)hatenaConsumerKey {
	return @"rtu/vY4jfiA3DQ==";
}

- (NSString*)hatenaSecret {
	return @"gFtqGv4/toRYlX/PT160+9fcrAU=";
}

- (NSString *)plurkAppSecret {
  return @"YYQUAeAPY9YMcCP5ol0dB6epaaMFT10C";
}

- (NSString *)plurkCallbackURL {
  return @"https://github.com/ShareKit/ShareKit";
}


- (NSString *) dropboxAppKey {
    //return @"n18olaziz6f8752"; //This app key has whole dropbox permission. Do not forget to change also dropboxAppSecret, dropboxRootFolder and url scheme in ShareKit demo app-info.plist if you wish to use it.
    return @"gb82qlxy5dx728y"; //This app key has sandbox permission
}
- (NSString *) dropboxAppSecret {
    //return @"6cjsemxx6i2qdvc";
    return @"rrk959vgkotv9v1";
}

- (NSString *) dropboxRootFolder {
    return @"sandbox";
    //return @"dropbox";
}
- (NSNumber *)dropboxShouldOverwriteExistedFile {
    return [NSNumber numberWithBool:NO];
}
-(NSString *)youTubeConsumerKey
{
    return @"210716542944.apps.googleusercontent.com";
}

-(NSString *)youTubeSecret
{
    return @"aaHCtV3LhzFE6XSFcKobb7HU";
}

- (NSString*)bufferClientID
{
	return @"518cdcb0872cad4744000038";
}

- (NSString*)bufferClientSecret
{
	return @"1bf70db9032207624e2ad58fb24b1593";
}

- (NSString *)imgurClientID {
    return @"a0467900dd97d89";
}

- (NSString *)imgurClientSecret {
    return @"cd4b907f1de7c7a901f055d5d2cd27415e43f7f3";
}

- (NSString *)imgurCallbackURL {
    return @"https://imgur.com";
}

#pragma mark - UI Configuration : Basic

- (NSNumber *)useAppleShareUI {
    return @YES;
}

- (UIColor*)barTintForView:(UIViewController*)vc {    
	
    if ([NSStringFromClass([vc class]) isEqualToString:@"SHKTwitter"]) 
        return [UIColor colorWithRed:0 green:151.0f/255 blue:222.0f/255 alpha:1];
    
    if ([NSStringFromClass([vc class]) isEqualToString:@"SHKFacebook"]) 
        return [UIColor colorWithRed:59.0f/255 green:89.0f/255 blue:152.0f/255 alpha:1];
    
    return nil;
}

@end
