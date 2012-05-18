/*
 * ENCredentialStore.h
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

#import <UIKit/UIKit.h>
#import "ENCredentials.h"

// Permanent store of Evernote credentials.
// Credentials are unique per (host,consumer key) tuple.
@interface ENCredentialStore : NSObject

// Load the credential store from user defaults.
+ (ENCredentialStore *)load;

// Save the credential store to user defaults.
- (void)save;

// Delete the credential store from user defaults.
// Leaves the keychain intact.
- (void)delete;

// Add credentials to the store.
// Also saves the authentication token to the keychain.
- (void)addCredentials:(ENCredentials *)credentials;

// Look up the credentials for the given host.
- (ENCredentials *)credentialsForHost:(NSString *)host;

// Remove credentials from the store.
// Also deletes the credentials' auth token from the keychain.
- (void)removeCredentials:(ENCredentials *)credentials;

// Remove all credentials from the store.
// Also deletes the credentials' auth tokens from the keychain.
- (void)clearAllCredentials;

@end
