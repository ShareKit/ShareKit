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
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Saving to %@", [[sharer class] sharerTitle])];
}

- (void)sharerFinishedSending:(SHKSharer *)sharer
{
	if (!sharer.quiet)
		[[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"Saved!")];
}

- (void)sharer:(SHKSharer *)sharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
    
    [[SHKActivityIndicator currentIndicator] hide];

    //if user sent the item already but needs to relogin we do not show alert
    if (!sharer.quiet && sharer.pendingAction != SHKPendingShare && sharer.pendingAction != SHKPendingSend)
	{				
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Error")
									 message:sharer.lastError!=nil?[sharer.lastError localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
    }		
    if (shouldRelogin) {        
        [sharer promptAuthorization];
	}
}

- (void)sharerCancelledSending:(SHKSharer *)sharer
{

}

- (void)sharerAuthDidFinish:(SHKSharer *)sharer success:(BOOL)success
{

}

@end
