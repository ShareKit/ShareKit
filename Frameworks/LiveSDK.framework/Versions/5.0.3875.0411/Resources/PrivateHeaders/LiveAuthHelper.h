//
//  LiveAuthHelper.h
//  Live SDK for iOS
//
//  Copyright 2014 Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "LiveConnectSession.h"

@interface LiveAuthHelper : NSObject

+ (NSBundle *) getSDKBundle;

+ (UIImage *) getBackButtonImage;

+ (NSArray *) normalizeScopes:(NSArray *)scopes;

+ (BOOL) isScopes:(NSArray *)scopes1
         subSetOf:(NSArray *)scopes2;

+ (NSURL *) buildAuthUrlWithClientId:(NSString *)clientId
                         redirectUri:(NSString *)redirectUri
                              scopes:(NSArray *)scopes;

+ (NSData *) buildGetTokenBodyDataWithClientId:(NSString *)clientId
                                   redirectUri:(NSString *)redirectUri
                                      authCode:(NSString *)authCode;

+ (NSData *) buildRefreshTokenBodyDataWithClientId:(NSString *)clientId
                                      refreshToken:(NSString *)refreshToken
                                             scope:(NSArray *)scopes;

+ (void) clearAuthCookie;

+ (NSError *) createAuthError:(NSInteger)code
                         info:(NSDictionary *)info;

+ (NSError *) createAuthError:(NSInteger)code
                     errorStr:(NSString *)errorStr
                  description:(NSString *)description
                   innerError:(NSError *)innerError;

+ (NSURL *) getRetrieveTokenUrl;

+ (NSString *) getDefaultRedirectUrlString;

+ (BOOL) isiPad;

+ (id) readAuthResponse:(NSData *)data;

+ (BOOL) isSessionValid:(LiveConnectSession *)session;

+ (BOOL) shouldRefreshToken:(LiveConnectSession *)session
               refreshToken:(NSString *)refreshToken;

+ (void) overrideLoginServer:(NSString *)loginServer
                   apiServer:(NSString *)apiServer;

@end
