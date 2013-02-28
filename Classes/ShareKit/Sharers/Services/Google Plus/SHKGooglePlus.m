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

@end
