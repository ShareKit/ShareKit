//
//  SHKOfflineSharer.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/22/10.

//
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
//
//

#import "SHKOfflineSharer.h"
#import "SHKSharer_protected.h"

@interface SHKOfflineSharer ()

@property (strong) NSDictionary *savedShareDictionary;
@property BOOL isShareFinished;

@end

@implementation SHKOfflineSharer


- (id)initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    
    if (self)
	{
        _savedShareDictionary = dictionary;
	}
	return self;
}

- (void)main
{
	// Make sure it hasn't been cancelled
	if ([self isCancelled]) return;
    
    id itemData = self.savedShareDictionary[@"item"];
    
    //graceful exit for previous offline sharer version. Used to be NSDictonary. If we encounter old version of saved item, it is simply discarded and the app does not crash.
    if (![itemData isKindOfClass:[NSData class]]) return;
    
    SHKItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
    NSString *sharerID = self.savedShareDictionary[@"sharer"];
	
    //make sure that input data are complete
    if (!item || !sharerID) return;    
    
    // create sharer
	SHKSharer *sharer = [[NSClassFromString(sharerID) alloc] init];
	sharer.item = item;
	sharer.quiet = YES;
	sharer.shareDelegate = self;
	
	if (![sharer isAuthorized]) return;
    
    self.isShareFinished = NO;
    
    [sharer tryToSend];
    
    //keep runloop alive to wait for asynchronous share callback
    do {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    } while (!self.isShareFinished);
}

#pragma mark -
#pragma mark SHKSharerDelegate

- (void)sharerStartedSending:(SHKSharer *)aSharer { }

- (void)sharerFinishedSending:(SHKSharer *)aSharer
{
    self.isShareFinished = YES;
}

- (void)sharer:(SHKSharer *)aSharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
    self.isShareFinished = YES;
}

- (void)sharerCancelledSending:(SHKSharer *)aSharer
{
    self.isShareFinished = YES;
}

- (void)sharerAuthDidFinish:(SHKSharer *)sharer success:(BOOL)success { }
- (void)sharerShowBadCredentialsAlert:(SHKSharer *)sharer { }
- (void)sharerShowOtherAuthorizationErrorAlert:(SHKSharer *)sharer { }
- (void)hideActivityIndicatorForSharer:(SHKSharer *)sharer { }
- (void)displayActivity:(NSString *)activityDescription forSharer:(SHKSharer *)sharer { }
- (void)displayCompleted:(NSString *)completionText forSharer:(SHKSharer *)sharer { }
- (void)showProgress:(CGFloat)progress forSharer:(SHKSharer *)sharer { }

@end
