//
//  SHKOAuthSharer.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

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

#import <Foundation/Foundation.h>
#import "SHKSharer.h"
#import "OAuthConsumer.h"
#import "SHKOAuthViewDelegate.h"

@interface SHKOAuthSharer : SHKSharer <SHKOAuthViewDelegate>

@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *secretKey;
@property (nonatomic, strong) NSURL *authorizeCallbackURL;

@property (nonatomic, strong) NSURL *authorizeURL;
@property (nonatomic, strong) NSURL *accessURL;
@property (nonatomic, strong) NSURL *requestURL;

@property (strong) OAConsumer *consumer;
@property (strong) OAToken *requestToken;
@property (strong) OAToken *accessToken;

@property (strong) id<OASignatureProviding> signatureProvider;

@property (nonatomic, strong) NSDictionary *authorizeResponseQueryVars;

#pragma mark -
#pragma mark OAuth Authorization

- (void)tokenRequest;
- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest;
- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)tokenRequestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;

- (void)tokenAuthorize;

- (void)tokenAccess;
- (void)tokenAccess:(BOOL)refresh;
- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest;
- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data;
- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error;

- (void)storeAccessToken;
- (BOOL)restoreAccessToken;
- (void)refreshToken;

@end
