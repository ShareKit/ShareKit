/*
 * ENCredentials.m
 * evernote-sdk-ios
 *
 * Copyright 2012 Evernote Corporation
 * All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *  
 * 1. Redistributions of source code must retain the above copyright notice, this 
 *    list of conditions and the following disclaimer.
 *     
 * 2. Redistributions in binary form must reproduce the above copyright notice, 
 *    this list of conditions and the following disclaimer in the documentation 
 *    and/or other materials provided with the distribution.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "ENCredentials.h"
#import "SSKeychain.h"

@interface ENCredentials()

@end

@implementation ENCredentials

@synthesize host = _host;
@synthesize edamUserId = _edamUserId;
@synthesize noteStoreUrl = _noteStoreUrl;
@synthesize authenticationToken = _authenticationToken;

- (void)dealloc
{
    [_host release];
    [_edamUserId release];
    [_noteStoreUrl release];
    [_authenticationToken release];
    [super dealloc];
}

- (id)initWithHost:(NSString *)host
        edamUserId:(NSString *)edamUserId
      noteStoreUrl:(NSString *)noteStoreUrl
authenticationToken:(NSString *)authenticationToken
{
    self = [super init];
    if (self) {
        self.host = host;
        self.edamUserId = edamUserId;
        self.noteStoreUrl = noteStoreUrl;
        self.authenticationToken = authenticationToken;
    }
    return self;
}

- (BOOL)saveToKeychain
{
    // auth token gets saved to the keychain
    NSError *error;
    BOOL success = [SSKeychain setPassword:_authenticationToken 
                                forService:self.host
                                   account:self.edamUserId 
                                     error:&error];
    if (!success) {
        NSLog(@"Error saving to keychain: %@ %d", error, error.code);
        return NO;
    } 
    return YES;
}

- (void)deleteFromKeychain
{
    [SSKeychain deletePasswordForService:self.host account:self.edamUserId];
}

- (NSString *)authenticationToken
{
    NSError *error;
    NSString *token = [SSKeychain passwordForService:self.host account:self.edamUserId error:&error];
    if (!token) {
        NSLog(@"Error getting password from keychain: %@", error);
    }
    return token;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.host forKey:@"host"];
    [encoder encodeObject:self.edamUserId forKey:@"edamUserId"];
    [encoder encodeObject:self.noteStoreUrl forKey:@"noteStoreUrl"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.host = [decoder decodeObjectForKey:@"host"];
        self.edamUserId = [decoder decodeObjectForKey:@"edamUserId"];
        self.noteStoreUrl = [decoder decodeObjectForKey:@"noteStoreUrl"];
    }
    return self;
}

@end
