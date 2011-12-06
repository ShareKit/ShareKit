//
//  SHKVkontakte.h
//  forismatic
//
//  Created by MacBook on 05.12.11.
//  Copyright (c) 2011 Alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHKSharer.h"
#import "SHKVkontakteForm.h"

static NSString *const kSHKVkonakteUserId=@"kSHKVkontakteUserId";
static NSString *const kSHKVkontakteAccessTokenKey=@"kSHKVkontakteAccessToken";
static NSString *const kSHKVkontakteExpiryDateKey=@"kSHKVkontakteExpiryDate";

@interface SHKVkontakte : SHKSharer
{
	BOOL isCaptcha;
}

@property (nonatomic, retain) NSString *accessUserId;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSString *expirationDate;

- (void)sendForm:(SHKVkontakteForm *)form;
- (void)authComplete;

@end
