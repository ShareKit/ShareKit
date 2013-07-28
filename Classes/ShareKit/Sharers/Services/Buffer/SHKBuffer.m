//
//  SHKBuffer.m
//  Buffer
//
//  Created by Andrew Yates on 26/04/2013.
//  Copyright (c) 2013 Buffer Inc. All rights reserved.
//

#import "SHKBuffer.h"
#import "SHKConfiguration.h"
#import "BufferSDK.h"

@implementation SHKBuffer

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Buffer";
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareImage
{
    return NO;
}

+ (BOOL)canShareOffline
{
    // Offline sharing is built into the Buffer iOS SDK, plan to get this working within ShareKit soon!
	return NO;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return NO;
}

- (BOOL)requiresShortenedURL
{
    return ![SHKCONFIG(bufferShouldShortenURLS) boolValue];
}


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    // Buffer SDK handles authrorisation with Buffer.
	return [BufferSDK isLoggedIn];
}

- (void)promptAuthorization {
    // Buffer SDK handles authrorisation with Buffer, so display sheet even if not logged in.
    
    BOOL shouldShortenURL = self.item.URL;
    if (shouldShortenURL && [self requiresShortenedURL]) {
        [self shortenURL];
        return;
    }
    
    [self show];
}

+ (BOOL)handleOpenURL:(NSURL*)url {
    [[BufferSDK sharedAPI] handleOpenURL:url];
    return YES;
}

+(void)logout {
    // Buffer SDK handles authrorisation with Buffer, call logout method on BufferSDK
	[BufferSDK logout];
}


#pragma mark -
#pragma mark Show UI Methods
- (BOOL)send {
    
    NSString *updateText = @"";
    
    if (self.item.shareType == SHKShareTypeURL) {
        NSString *url = [self.item.URL absoluteString];
		
		if (self.item.text){
            updateText = [NSString stringWithFormat:@"%@ %@", self.item.text, url];
        } else if(self.item.title){
            updateText = [NSString stringWithFormat:@"%@ %@", self.item.title, url];
        } else {
            updateText = url;
        }
	} else if (self.item.shareType == SHKShareTypeText) {
		updateText = self.item.text;
    }
    
    [[BufferSDK sharedAPI] setClientID:SHKCONFIG(bufferClientID) andClientSecret:SHKCONFIG(bufferClientSecret)];
    
    [[BufferSDK sharedAPI] shouldShortenURLS:[SHKCONFIG(bufferShouldShortenURLS) boolValue]];
    
    // BufferSDKResources.bundle is contained within ShareKit.bundle so pass this to BufferSDK.
    NSString *bundleRoot = [[NSBundle mainBundle] pathForResource:@"ShareKit" ofType:@"bundle"];
    bundleRoot = [NSString stringWithFormat:@"%@/BufferSDKResources.bundle", bundleRoot];
    [[BufferSDK sharedAPI] setResourceBundlePath:bundleRoot];
    
    // Buffer presents the view using addChildViewController to display transparent modal.
    [BufferSDK presentBufferSheetWithText:updateText completionBlock:^(NSDictionary *response) {
        [self sendDidFinish];
    }];
    
    return YES;
}

@end
