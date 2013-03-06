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
#import "SHKSharer.h"

@implementation SHKOfflineSharer

- (void)dealloc
{
	[_item release];
	[_sharerId release];
	[_uid release];
	[_runLoopThread release];
	[_sharer release];
	[super dealloc];
}

- (id)initWithItem:(SHKItem *)i forSharer:(NSString *)s uid:(NSString *)u
{
	if (self = [super init])
	{
		_item = [i retain];
		_sharerId = [s retain];
		_uid = [u retain];
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    
    if (self)
	{
        SHKItem *item = [SHKItem itemFromDictionary:[dictionary objectForKey:@"item"]];
        NSString *sharerID = [dictionary objectForKey:@"sharer"];
        NSString *uid = [dictionary objectForKey:@"uid"];
		_item = [item retain];
		_sharerId = [sharerID retain];
		_uid = [uid retain];
	}
	return self;
}

- (void)main
{
	// Make sure it hasn't been cancelled
	if (![self shouldRun])
		return;	
	
    //make sure that input data are complete
    if (!self.item || !self.sharerId) {
        return;
    }
    
	// Save the thread so we can spin up the run loop later
	self.runLoopThread = [NSThread currentThread];
	
	// Run actual sharing on the main thread to avoid thread issues
	[self performSelectorOnMainThread:@selector(share) withObject:nil waitUntilDone:YES];
	
	// Keep the operation alive while we perform the send async
	// This way only one will run at a time
	while([self shouldRun]) 
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
}

- (void)share
{	
	// create sharer
	SHKSharer *aSharer = [[NSClassFromString(self.sharerId) alloc] init];
	aSharer.item = self.item;
	aSharer.quiet = YES;
	aSharer.shareDelegate = self;
    
    self.sharer = aSharer;
    [aSharer release];
	
	if (![self.sharer isAuthorized])
	{
		[self finish];
		return;
	}
    
    //if the item was saved using old method, reconstruct attachments
    if (self.uid) {
        
        // reload image from disk and remove the file
        NSString *path;
        if (self.item.shareType == SHKShareTypeImage)
        {
            path = [[SHK offlineQueuePath] stringByAppendingPathComponent:self.uid];
            self.sharer.item.image = [UIImage imageWithContentsOfFile:path];
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            
        }
        
        // reload file from disk and remove the file
        else if (self.item.shareType == SHKShareTypeFile)
        {
            path = [[SHK offlineQueueListPath] stringByAppendingPathComponent:self.uid];
            self.sharer.item.data = [NSData dataWithContentsOfFile:[[SHK offlineQueuePath] stringByAppendingPathComponent:self.uid]];
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil]; 
        }
    }
	
	[self.sharer tryToSend];
}

- (BOOL)shouldRun
{
	return ![self isCancelled] && ![self isFinished] && !self.readyToFinish;
}

- (void)finish
{	
	self.readyToFinish = YES;
	[self performSelector:@selector(lastSpin) onThread:self.runLoopThread withObject:nil waitUntilDone:NO];
}

- (void)lastSpin
{
	// Just used to make the run loop spin
}

#pragma mark -
#pragma mark SHKSharerDelegate

- (void)sharerStartedSending:(SHKSharer *)aSharer
{
	
}

- (void)sharerFinishedSending:(SHKSharer *)aSharer
{	
	self.sharer.shareDelegate = nil;
	[self finish];
}

- (void)sharer:(SHKSharer *)aSharer failedWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
	self.sharer.shareDelegate = nil;
	[self finish];
}

- (void)sharerCancelledSending:(SHKSharer *)aSharer
{
	self.sharer.shareDelegate = nil;
	[self finish];
}

- (void)sharerAuthDidFinish:(SHKSharer *)sharer success:(BOOL)success
{

}

- (void)sharerShowBadCredentialsAlert:(SHKSharer *)sharer
{
    
}

- (void)sharerShowOtherAuthorizationErrorAlert:(SHKSharer *)sharer
{
    
}

@end
