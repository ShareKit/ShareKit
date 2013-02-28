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

@synthesize mGooglePlusShare,mShareBuilder;

static SHKGooglePlus *sharedInstance = nil;

+ (SHKGooglePlus *)shared {
	@synchronized(self) {
		if (!sharedInstance)
			sharedInstance = [SHKGooglePlus new];
	}
	return sharedInstance;
}

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

+ (BOOL)canAutoShare
{
	return NO;
}

#pragma mark -
#pragma mark Authorization

+ (BOOL)requiresAuthentication {
	return NO;
}

+ (void)logout {
	[super logout];
}

#pragma mark -
#pragma mark Share API Methods

- (void)show {
    self.mShareBuilder = [self.mGooglePlusShare shareDialog];
    
    switch ([self.item shareType]) {
        case SHKShareTypeURL:
            [self.mShareBuilder setURLToShare:self.item.URL];
            [self.mShareBuilder setPrefillText:self.item.text];
            break;
        default:
        case SHKShareTypeText:
            [self.mShareBuilder setPrefillText:self.item.text];
            break;
    }
    [self tryToSend];
}

- (BOOL)send {
    BOOL returnValue = [self.mShareBuilder open];
    [self sendDidStart];
    return returnValue;
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

- (void)dealloc {
    self.mGooglePlusShare.delegate = nil;
    self.mGooglePlusShare = nil;
    self.mShareBuilder = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark GPPShareDelegate

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared {
    if (shared)
        [self sendDidFinish];
    else
        [self sendDidCancel];
}

@end
