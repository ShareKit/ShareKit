/*
 * EvernoteSession.h
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

#import <Foundation/Foundation.h>
#import "EDAM.h"

// For Evernote-related error codes, see EDAMErrors.h

// Post-authentication callback type, defined for easy reuse.
typedef void (^EvernoteAuthCompletionHandler)(NSError *error);

/*
 * Evernote Session, using OAuth to authenticate.
 */
@interface EvernoteSession : NSObject

@property (nonatomic, retain) NSString *host;
@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;

// Are we authenticated?
@property (nonatomic, readonly) BOOL isAuthenticated;

// Evernote auth token, to be passed to any NoteStore methods.
// Will only be non-nil once we've authenticated.
@property (nonatomic, readonly) NSString *authenticationToken;

// Shared dispatch queue for API operations.
@property (nonatomic, readonly) dispatch_queue_t queue;

// Set up the shared session.
// @"sandbox.evernote.com" should be used for testing; 
// @"www.evernote.com" for production apps.
+ (void)setSharedSessionHost:(NSString *)host 
                 consumerKey:(NSString *)consumerKey 
              consumerSecret:(NSString *)consumerSecret;

// Get the singleton shared session.
+ (EvernoteSession *)sharedSession;

// URL handler. Call this from your AppDelegate's application:handleOpenURL: method.
- (BOOL)handleOpenURL:(NSURL *)url;

// Authenticate, calling the given handler upon completion.
- (void)authenticateWithCompletionHandler:(EvernoteAuthCompletionHandler)completionHandler;

// Clear authentication.
- (void)logout;

// Create a new UserStore client for EDAM calls.
// May throw NSException.
// This object is NOT threadsafe.
- (EDAMUserStoreClient *)userStore;

// Create a new NoteStore client for EDAM calls.
// May throw NSException.
// This object is NOT threadsafe.
- (EDAMNoteStoreClient *)noteStore;

// Abstracted into a method to support unit testing.
- (NSURLConnection *)connectionWithRequest:(NSURLRequest *)request;

// Exposed for unit testing.
- (void)verifyConsumerKeyAndSecret;

// Exposed for unit testing.
- (void)verifyCFBundleURLSchemes;

// Abstracted into a method to support unit testing.
- (void)openBrowserWithURL:(NSURL *)url;

// Abstracted into a method to support unit testing.
- (void)saveCredentialsWithEdamUserId:(NSString *)edamUserId 
                         noteStoreUrl:(NSString *)noteStoreUrl
                  authenticationToken:(NSString *)authenticationToken;

@end
