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


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    // Buffer SDK handles authrorisation with Buffer.
	return [BufferSDK isLoggedIn];
}

- (void)promptAuthorization {
    // Buffer SDK handles authrorisation with Buffer, so display sheet even if not logged in.
    
    BOOL shouldShortenURL = self.item.URL;
    if (shouldShortenURL) {
        [self bufferShortenURL];
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


#pragma mark - SHK Shorten Links

- (void)bufferShortenURL
{
	NSString *bitLyLogin = SHKCONFIG(bitLyLogin);
	NSString *bitLyKey = SHKCONFIG(bitLyKey);
	BOOL bitLyConfigured = [bitLyLogin length] > 0 && [bitLyKey length] > 0;
	
	if (bitLyConfigured == NO || ![SHK connected]) {
        SHKLog(@"URL was not shortened! Make sure you have bit.ly credentials");
        [self show];
        return;
    }
	
	[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Shortening URL...")];
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[NSMutableString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apikey=%@&longUrl=%@&format=txt",
																		  bitLyLogin,
																		  bitLyKey,
																		  SHKEncodeURL(self.item.URL)
																		  ]]
											 params:nil
										   delegate:self
								 isFinishedSelector:@selector(bufferShortenFinished:)
											 method:@"GET"
										  autostart:YES] autorelease];
}

- (void)bufferShortenFinished:(SHKRequest *)aRequest
{
	[[SHKActivityIndicator currentIndicator] hide];
	
	NSString *result = [[aRequest getResult] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	if (!aRequest.success || result == nil || [NSURL URLWithString:result] == nil)
	{
		SHKLog(@"URL was not shortened! Error response:%@", result);
	}
	else
	{
        //if really shortened, set new URL
		if (![result isEqualToString:@"ALREADY_A_BITLY_LINK"]) {
            NSURL *newURL = [NSURL URLWithString:result];
            self.item.URL = newURL;
        }
	}
    
    [self show];
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
