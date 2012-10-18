//
//  SHKTumblerV2.h
//  ShareKit
//
//  Created by David Boyes on 12/09/12.
//
//

#import "SHKOAuthSharer.h"

@interface SHKTumblrV2 : SHKOAuthSharer
{
	BOOL xAuth;
}

@property BOOL xAuth;

#pragma mark -
#pragma mark Share API Methods

- (void)sendText;
- (void)sendTextTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendTextTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;
- (void)sendURL;
- (void)sendURLTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendURLTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;
- (void)sendImage;
- (void)sendImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)sendImageTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;
- (void)getUserInfo;
- (void)getUserInfo:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)getUserInfo:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;



@end
