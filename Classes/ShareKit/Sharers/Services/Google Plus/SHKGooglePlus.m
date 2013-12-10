//
//  SHKGooglePlus.m
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

#import "SHKGooglePlus.h"

#import "SharersCommonHeaders.h"

#import <GooglePlus/GPPSignIn.h>
#import "GTLPlusPerson.h"

@interface SHKGooglePlus ()

@property BOOL isDisconnecting;

@end

@implementation SHKGooglePlus

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"Google+"); }

+ (BOOL)canShareURL { return YES; }
+ (BOOL)canShareText { return YES; }

+ (BOOL)canShareOffline { return NO; }
+ (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Life Cycles

- (id)init {
    
    self = [super init];
    if (self) {
        
        [[GPPSignIn sharedInstance] setClientID:SHKCONFIG(googlePlusClientId)];
    }
    return self;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    
    BOOL alreadyAuthenticated = [[GPPSignIn sharedInstance] authentication];
    BOOL result = alreadyAuthenticated;
    
    if (!alreadyAuthenticated) {
        result = [[GPPSignIn sharedInstance] trySilentAuthentication];
    }
    
	return result;
}

- (void)promptAuthorization {
    
    [[GPPSignIn sharedInstance] setDelegate:self];
    [[GPPSignIn sharedInstance] setShouldFetchGooglePlusUser:YES];
    [[GPPSignIn sharedInstance] authenticate];
}

+ (void)logout {

    SHKGooglePlus *sharer = (SHKGooglePlus *)[[GPPSignIn sharedInstance] delegate];
    if (!sharer) {
        
        sharer = [[SHKGooglePlus alloc] init];
        [[GPPSignIn sharedInstance] setDelegate:sharer];
        [[SHK currentHelper] keepSharerReference:sharer];
    }
    
    sharer.isDisconnecting = YES;
    [[GPPSignIn sharedInstance] disconnect];
}

+ (NSString *)username {
    
    [[GPPSignIn sharedInstance] trySilentAuthentication];
    GTLPlusPerson *loggedUser = [[GPPSignIn sharedInstance] googlePlusUser];
    NSString *result = loggedUser.displayName;
    return result;
}

#pragma mark - GPPSignInDelegate methods

// The authorization has finished and is successful if |error| is |nil|.
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
    
    if (!error) {
        [self authDidFinish:YES];
    } else {
        [self authDidFinish:NO];
        SHKLog(@"auth error: %@", [error description]);
    }
    if (!self.isDisconnecting) {
        [[SHK currentHelper] removeSharerReference:self]; //ref will be removed in didDisconnectWithError: if logoff is in progress
    }
}

- (void)didDisconnectWithError:(NSError *)error {
    if (error) {
        SHKLog(@"Google plus could not disconnect with error: %@", error);
    } else {
        [self authDidFinish:NO]; //refresh UI
    }
    [[SHK currentHelper] removeSharerReference:self];
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send {
    
    //item validation is not needed, as GPPShareBuilder can be empty.
    
    [[GPPShare sharedInstance] setDelegate:self];
    id<GPPShareBuilder> mShareBuilder = [[GPPShare sharedInstance] shareDialog];
    
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
#pragma mark GPPShareDelegate

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared {
    
    if (shared) { 
        self.quiet = NO;
        [self sendDidFinish];
    } else {
        [self sendDidCancel];
    }
    [[SHK currentHelper] removeSharerReference:self];
}

#pragma mark -

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if (![[GPPSignIn sharedInstance] delegate] || ![[GPPShare sharedInstance] delegate]) {
        
        //the sharer does not exist anymore after safari trip. We have to recreate it so that delegate methods are called.
        SHKGooglePlus *gPlusSharer = [[SHKGooglePlus alloc] init];
        [[GPPSignIn sharedInstance] setDelegate:gPlusSharer];
        [[GPPShare sharedInstance] setDelegate:gPlusSharer];
        
        //otherwise the sharer would be deallocated prematurely and delegate methods might not be called. The reference is removed in delegate methods, see finishedSharing: or finishedWithAuth:error:.
        [[SHK currentHelper] keepSharerReference:gPlusSharer];
    }

    BOOL result = [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
    return result;
}

@end
