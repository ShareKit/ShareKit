//
//  SHKiOSSharer_Protected.h
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOSSharer.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@interface SHKiOSSharer ()

/*!
 Attempts to share self.item with SLComposeViewController. If SLComposeViewController was able to add all self.item properties (text, image, URL), item is shared.
 @param serviceType A string constant that identifies sharer's service, such as SLServiceTypeTwitter
 @return YES if SLComposeViewController accepted all self.item properties and has been presented to the user. NO if SLComposeViewController did not accept at least one of self.item's text, image or URL properties. In this case SLComposeViewController is not presented to the user.
 */
- (BOOL)shareWithServiceType:(NSString *)serviceType;

/*!
 Each iOS sharer should subclass this method. The value is used in superclass to check if user has account authorized etc.
 
 @return Appropriate accountTypeIdentifier for sharer subclass.
 */
- (NSString *)accountTypeIdentifier;

/*!
 Each iOS sharer should subclass this method. The value is used in superclass to present appropriate SLComposeViewController
 
 @return Appropriate serviceTypeIdentifier for sharer subclass.
 */
- (NSString *)serviceTypeIdentifier;

/*!
 Returns all accounts available for particular subclass
 
 @return ACAccounts available for this service
 */
- (NSArray *)availableAccounts;

/* returns nil by default. Subclasses which can pass tags directly in system dialogue might want to return properly concatenated tags ready to ship to service. */
- (NSString *)joinedTags;

/*! iOS sharer should call this when there is any problem during auth, e.g. user does not grant access
 @param error Error from social.framework authorization
 */
- (void)iOSAuthorizationFailedWithError:(NSError *)error;


@end
