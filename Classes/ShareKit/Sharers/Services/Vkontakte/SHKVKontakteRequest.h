//
//  SHKVKontakteRequest.h
//  ShareKit
//
//  Created by user on 11.12.12.
//
//

#import "SHKRequest.h"

@interface SHKVKontakteRequest : SHKRequest

@property (strong) NSData *paramsData;

- (id)initWithURL:(NSURL *)u paramsData:(NSData *)pD method:(NSString *)m completion:(RequestCallback)completionBlock;

@end
