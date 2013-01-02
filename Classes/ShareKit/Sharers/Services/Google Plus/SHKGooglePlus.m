//
//  SHKGooglePlus.m
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

#import "SHKGooglePlus.h"
#import "SHKConfiguration.h"

@interface SHKGooglePlus ()

@end

@implementation SHKGooglePlus

@synthesize mGooglePlusShare;

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Google Plus";
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
	return NO;
}

+ (BOOL)canGetUserInfo
{
    return NO;
}

#pragma mark -
#pragma mark Share API Methods

- (void)share {
    id<GPPShareBuilder> shareBuilder = [self.mGooglePlusShare shareDialog];
    
    shareBuilder = [shareBuilder setURLToShare:self.item.URL];
    shareBuilder = [shareBuilder setPrefillText:self.item.title];

    if (![shareBuilder open])
        [super share];
}

#pragma mark -
#pragma mark Life Cycles

- (id)init {
    self = [super init];
    if (self) {
        self.mGooglePlusShare = [[GPPShare alloc] initWithClientID:SHKCONFIG(googlePlusClientId)];
        self.mGooglePlusShare.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    self.mGooglePlusShare.delegate = nil;
    self.mGooglePlusShare = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark GPPShareDelegate

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared {
    
}

@end
