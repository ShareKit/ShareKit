//
//  SHKSharerDelegate.m
//  ShareKit
//
//  Created by Vilem Kurz on 2.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "SHKSharerDelegate.h"

@implementation SHKSharerDelegate

#pragma mark -
#pragma mark SHKSharerDelegate protocol methods

// These are used if you do not provide your own custom UI and delegate

- (void)sharerStartedSending:(SHKSharer *)sharer
{
	if (!sharer.quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Saving to %@", [[self class] sharerTitle])];
}

- (void)sharerFinishedSending:(SHKSharer *)sharer
{
	if (!sharer.quiet)
		[[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Saved!")];
}

- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
	if (!sharer.quiet)
	{
		[[SHKActivityIndicator currentIndicator] hide];
		
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Error")
									 message:sharer.lastError!=nil?[sharer.lastError localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		
		if (shouldRelogin)
			[sharer promptAuthorization];
	}
}

- (void)sharerCancelledSending:(SHKSharer *)sharer
{

}

- (void)sharerAuthDidFinish:(SHKSharer *)sharer success:(BOOL)success
{
	if (success) {
        //this saves info about user such as username for services, which do not store username in keychain e.g. facebook and twitter.
        NSString *userInfoKeyForSharer = [NSString stringWithFormat:@"kSHK%@UserInfo", [sharer title]];
        NSDictionary *savedUserInfo = [[NSUserDefaults standardUserDefaults] objectForKey:userInfoKeyForSharer];
        if ([[sharer class] canGetUserInfo] && !savedUserInfo) {
            [[sharer class] getUserInfo];
        }
    }
}

@end
