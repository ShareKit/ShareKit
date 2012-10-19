//
//  SHKLinkedInOAMutableURLRequest.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/22/11.
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

#import "SHKLinkedInOAMutableURLRequest.h"

@interface SHKLinkedInOAMutableURLRequest ()

- (NSString *)_signatureBaseString;

@end

@implementation SHKLinkedInOAMutableURLRequest

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider 
         callback:(NSString*)aCallback
{
    self = [super initWithURL:aUrl consumer:aConsumer token:aToken realm:aRealm signatureProvider:aProvider];
    
    if (self)
    {
        callback = [aCallback copy];
    }
    
    return self;
}

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding, NSObject>)aProvider
            nonce:(NSString *)aNonce
        timestamp:(NSString *)aTimestamp
         callback:(NSString*)aCallback
{
    self = [super initWithURL:aUrl consumer:aConsumer token:aToken realm:aRealm signatureProvider:aProvider nonce:aNonce timestamp:aTimestamp];
    
    if (self)
    {
        callback = [aCallback copy];
    }
    
    return self;
}

- (void)dealloc
{
    [callback release];
    [super dealloc];
}

- (void)prepare
{
	if (didPrepare) {
		return;
	}
	didPrepare = YES;
    // sign
	// Secrets must be urlencoded before concatenated with '&'
	// TODO: if later RSA-SHA1 support is added then a little code redesign is needed
    signature = [signatureProvider signClearText:[self _signatureBaseString]
                                      withSecret:[NSString stringWithFormat:@"%@&%@",
												  [consumer.secret encodedURLString],
                                                  [token.secret encodedURLString]]];
    
    // set OAuth headers
    NSString *oauthToken;
    if ([token.key isEqualToString:@""])
        oauthToken = @""; // not used on Request Token transactions
    else
        oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", [token.key encodedURLString]];
    
    NSString *oauthCallback;
    if (callback && callback.length > 0)
        oauthCallback = [NSString stringWithFormat:@"oauth_callback=\"%@\", ", [callback encodedURLString]];
    else
        oauthCallback = @"";
	
	NSMutableString *extraParameters = [NSMutableString string];
	
	// Adding the optional parameters in sorted order isn't required by the OAuth spec, but it makes it possible to hard-code expected values in the unit tests.
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)])
	{
		[extraParameters appendFormat:@", %@=\"%@\"",
		 [parameterName encodedURLString],
		 [[extraOAuthParameters objectForKey:parameterName] encodedURLString]];
	}
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth realm=\"%@\", %@oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"%@",
                             [realm encodedURLString],
                             oauthCallback,
                             [consumer.key encodedURLString],
                             oauthToken,
                             [[signatureProvider name] encodedURLString],
                             [signature encodedURLString],
                             timestamp,
                             nonce,
							 extraParameters];
    
    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}


#pragma mark -
#pragma mark Private

- (NSString *)_signatureBaseString
{
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:(7)]; // 7 being the number of OAuth params in the Signature Base String

    if (callback && callback.length > 0) {
        [parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_callback" value:callback] URLEncodedNameValuePair]];
    }

	[parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_consumer_key" value:consumer.key] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_signature_method" value:[signatureProvider name]] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_timestamp" value:timestamp] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_nonce" value:nonce] URLEncodedNameValuePair]];
	[parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_version" value:@"1.0"] URLEncodedNameValuePair]];
    
    if (![token.key isEqualToString:@""]) {
        [parameterPairs addObject:[[OARequestParameter requestParameter:@"oauth_token" value:token.key] URLEncodedNameValuePair]];
    }
    
	
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[parameterPairs addObject:[[OARequestParameter requestParameter:[parameterName encodedURLString] value: [[extraOAuthParameters objectForKey:parameterName] encodedURLString]] URLEncodedNameValuePair]];
	}
	
	if (![[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
		for (OARequestParameter *param in [self parameters]) {
			[parameterPairs addObject:[param URLEncodedNameValuePair]];
		}
	}
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *ret = [NSString stringWithFormat:@"%@&%@&%@",
					 [self HTTPMethod],
					 [[[self URL] URLStringWithoutQuery] encodedURLString],
					 [normalizedRequestParameters encodedURLString]];
	
	return ret;
}


@end
