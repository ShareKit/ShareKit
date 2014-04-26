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

#define ALLOWED_VIDEO_SIZE 1037741824 //1GB in Bytes
#define ALLOWED_IMAGE_SIZE 37748736 //36MB in Bytes

@interface SHKGooglePlus ()

@property BOOL isDisconnecting;

@end

@implementation SHKGooglePlus

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"Google+"); }

+ (BOOL)canShareURL { return YES; }
+ (BOOL)canShareText { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file {
    
    BOOL isAllowedVideo = [file.mimeType hasPrefix:@"video"] && file.size < ALLOWED_VIDEO_SIZE;
    BOOL isAllowedImage = [file.mimeType hasPrefix:@"image"] && file.size < ALLOWED_IMAGE_SIZE;
    if (isAllowedVideo || isAllowedImage) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)canShareOffline { return NO; }
+ (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Life Cycles

- (id)init {
    
    self = [super init];
    if (self) {
        
        [[GPPSignIn sharedInstance] setClientID:SHKCONFIG(googlePlusClientId)];
        [[GPPSignIn sharedInstance] setShouldFetchGooglePlusUser:YES];
    }
    return self;
}

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    
    BOOL alreadyAuthenticated = [[GPPSignIn sharedInstance] authentication] != nil;
    BOOL result = alreadyAuthenticated;
    
    if (!alreadyAuthenticated) {
        [[GPPSignIn sharedInstance] setDelegate:self];
        result = [[GPPSignIn sharedInstance] trySilentAuthentication];
        [[SHK currentHelper] keepSharerReference:self];
        
        //will be shared in auth callback. Without this Google+ native share sheet says: "User must be signed in to use the native sharebox." Here we can get if user has authorized before, but the app was killed/hibernated in the meantime
        if (self.item) self.pendingAction = SHKPendingShare;
    }
    
	return result;
}

- (void)authorizationFormShow {
    
    [self saveItemForLater:SHKPendingShare];
    
    [[GPPSignIn sharedInstance] setDelegate:self];
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
        [self restoreItem];
        [self tryPendingAction];
    } else {
        [self authDidFinish:NO];
        SHKLog(@"auth error: %@", [error description]);
        if (error.code == 400) {//400 = "invalid_grant"
            [self promptAuthorization];
        }
        
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
    id<GPPShareBuilder> mShareBuilder = [[GPPShare sharedInstance] nativeShareDialog];
    
    [mShareBuilder setPrefillText:self.item.text];
    
    switch ([self.item shareType]) {
        case SHKShareTypeURL:
            [mShareBuilder setURLToShare:self.item.URL];
            break;
        case SHKShareTypeText:
            break;
        case SHKShareTypeImage:
            [(id<GPPNativeShareBuilder>)mShareBuilder attachImage:self.item.image];
            break;
        case SHKShareTypeFile:
            if ([self.item.file.mimeType hasPrefix:@"image"]) {
                [(id<GPPNativeShareBuilder>)mShareBuilder attachImageData:[self.item.file data]];
            } else { //video
                [(id<GPPNativeShareBuilder>)mShareBuilder attachVideoURL:self.item.file.URL];
            }
            break;
        default:
            return NO;
            break;
    }
    self.quiet = YES; //if user cancels, on return blinks activity indicator. This disables it, as we share in safari and it is hidden anyway
    [self sendDidStart];
    
    BOOL dialogOpenedSuccessfully = [mShareBuilder open];
    if (dialogOpenedSuccessfully) {
        [[SHK currentHelper] keepSharerReference:self];
    }
    return dialogOpenedSuccessfully;
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
