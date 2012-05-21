/*
 * ENAPI.h
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
#import "EDAM.h"
#import "ENAPI.h"
#import "EvernoteSDK.h"

@implementation ENAPI

@synthesize session = _session;
@dynamic noteStore;
@dynamic userStore;

- (void)dealloc
{
    [_session release];
    [super dealloc];
}

- (id)initWithSession:(EvernoteSession *)session
{
    self = [super init];
    if (self) {
        self.session = session;
    }
    return self;
}

- (EDAMNoteStoreClient *)noteStore
{
    return [self.session noteStore];
}

- (EDAMUserStoreClient *)userStore
{
    return [self.session userStore];    
}

- (NSError *)errorFromNSException:(NSException *)exception
{
    if (exception) {
        int errorCode = EDAMErrorCode_UNKNOWN;
        if ([exception respondsToSelector:@selector(errorCode)]) {
            // Evernote Thrift exception classes have an errorCode property
            errorCode = [(id)exception errorCode];
        } else if ([exception isKindOfClass:[TException class]]) {
            // treat any Thrift errors as a transport error
            // TODO: we could create separate error codes for the various TException subclasses
            errorCode = EvernoteSDKErrorCode_TRANSPORT_ERROR;
        }

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
        if ([exception respondsToSelector:@selector(parameter)]) {
            NSString *parameter = [(id)exception parameter];
            if (parameter) {
                [userInfo setValue:parameter forKey:@"parameter"];
            }
        }
        return [NSError errorWithDomain:EvernoteSDKErrorDomain code:errorCode userInfo:userInfo];
    }
    return nil;
}

- (void)invokeAsyncBoolBlock:(BOOL(^)())block
                     success:(void(^)(BOOL val))success
                     failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.session.queue, ^(void) {
        __block BOOL retVal = NO;
        @try {
            if (block) {
                retVal = block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success(retVal);
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               if (failure) {
                                   failure(error);
                               }
                           });
        }
    });
}

- (void)invokeAsyncInt32Block:(int32_t(^)())block
                      success:(void(^)(int32_t val))success
                      failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.session.queue, ^(void) {
        __block int32_t retVal = -1;
        @try {
            if (block) {
                retVal = block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success(retVal);
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               if (failure) {
                                   failure(error);
                               }
                           });
        }
    });
}

// use id instead of NSObject* so block type-checking is happy
- (void)invokeAsyncIdBlock:(id(^)())block
                   success:(void(^)(id))success
                   failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.session.queue, ^(void) {
        id retVal = nil;
        @try {
            if (block) {
                retVal = block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success(retVal);
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               if (failure) {
                                   failure(error);
                               }
                           });
        }
    });
}

- (void)invokeAsyncVoidBlock:(void(^)())block
                     success:(void(^)())success
                     failure:(void(^)(NSError *error))failure
{
    dispatch_async(self.session.queue, ^(void) {
        @try {
            if (block) {
                block();
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   if (success) {
                                       success();
                                   }
                               });
            }
        }
        @catch (NSException *exception) {
            NSError *error = [self errorFromNSException:exception];
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               if (failure) {
                                   failure(error);
                               }
                           });
        }
    }); 
}

@end