//
//  SHKGooglePlus.m
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

#import "SHKGooglePlus.h"

#import "SharersCommonHeaders.h"

@interface SHKGooglePlus ()

@property (nonatomic, strong) GPPShare *mGooglePlusShare;

@end

@implementation SHKGooglePlus

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Google+");
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

+ (BOOL)canShareOffline
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

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send {
    
    //item validation is not needed, as GPPShareBuilder can be empty.
    
    id<GPPShareBuilder> mShareBuilder = [self.mGooglePlusShare shareDialog];
    
    switch ([self.item shareType]) {
        case SHKShareTypeURL:
            [mShareBuilder setURLToShare:self.item.URL];
            [mShareBuilder setPrefillText:self.item.text];
            break;
        default:
        case SHKShareTypeText:
            [mShareBuilder setPrefillText:self.item.text];
            break;
    }
    
    self.quiet = YES; //if user cancels, on return blinks activity indicator. This disables it, as we share in safari and it is hidden anyway
    [self sendDidStart];
    return [mShareBuilder open];
}

#pragma mark -
#pragma mark Life Cycles

- (id)init {

        self = [super init];
        if (self) {
            _mGooglePlusShare = [[GPPShare alloc] initWithClientID:SHKCONFIG(googlePlusClientId)];
            _mGooglePlusShare.delegate = self;
        }
        return self;
}


#pragma mark -
#pragma mark GPPShareDelegate

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    SHKGooglePlus *gPlusSharer = [[SHKGooglePlus alloc] init];
    BOOL result = [gPlusSharer.mGooglePlusShare handleURL:url sourceApplication:sourceApplication annotation:annotation];
    return result;
}

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared {
    
    //[[SHKActivityIndicator currentIndicator] hide];
    if (shared) { 
        self.quiet = NO;
        [self sendDidFinish];
    } else {
        [self sendDidCancel];
    }
}

@end
