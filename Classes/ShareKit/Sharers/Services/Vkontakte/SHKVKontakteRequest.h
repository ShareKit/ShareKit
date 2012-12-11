//
//  SHKVKontakteRequest.h
//  ShareKit
//
//  Created by user on 11.12.12.
//
//

#import "SHKRequest.h"

@interface SHKVKontakteRequest : SHKRequest
{
    NSData *paramsData;
}

@property (retain) NSData *paramsData;

- (id)initWithURL:(NSURL *)u paramsData:(NSData *)pD delegate:(id)d isFinishedSelector:(SEL)s method:(NSString *)m autostart:(BOOL)autostart;


@end
