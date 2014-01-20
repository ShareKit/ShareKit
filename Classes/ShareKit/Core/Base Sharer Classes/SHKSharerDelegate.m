//
//  SHKSharerDelegate.m
//  ShareKit
//
//  Created by Vilem Kurz on 2.1.2012.
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "SHKSharerDelegate.h"
#import "SHKActivityIndicator.h"
#import "SHK.h"
#import "Debug.h"

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
    if (!sharer.quiet && sharer.pendingAction != SHKPendingShare && sharer.pendingAction != SHKPendingSend && sharer.pendingAction != SHKPendingRefreshToken)
	{				
		[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Error")
									 message:sharer.lastError!=nil?[sharer.lastError localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] show];
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
    //it is convenient to fetch user info after successful authorization. Not only you have username etc at your disposal, but there can be also various limits used by ShareKit to determine if the service can accept particular item (eg. video size) for this user. If it does not, ShareKit does not offer this service in share menu. SHKFacebook has a bug - it is crashing if you fetch user info alone after authorization. You have to share something to be really authorized. SHKFacebook has a very confusing implementation, thus rather than fix the real root cause I have decided to do not fetch userinfo in this case. I suggest to use SHKiOSFacebook wherever possible.
    if (success && [[sharer class] canGetUserInfo] &&![[sharer class] isEqual:NSClassFromString(@"SHKFacebook")]) {
        [[sharer class] getUserInfo];
    }
}

- (void)sharerShowBadCredentialsAlert:(SHKSharer *)sharer
{    
    NSString *errorMessage = SHKLocalizedString(@"Sorry, %@ did not accept your credentials. Please try again.", [[sharer class] sharerTitle]);
       
    [[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Login Error")
                                 message:errorMessage
                                delegate:nil
                       cancelButtonTitle:SHKLocalizedString(@"Close")
                       otherButtonTitles:nil] show];
}

- (void)sharerShowOtherAuthorizationErrorAlert:(SHKSharer *)sharer
{    
    NSString *errorMessage = SHKLocalizedString(@"Sorry, %@ encountered an error. Please try again.", [[sharer class] sharerTitle]);
    
    [[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Login Error")
                                 message:errorMessage
                                delegate:nil
                       cancelButtonTitle:SHKLocalizedString(@"Close")
                       otherButtonTitles:nil] show];
}

@end
