//
//  OAMutableURLRequest.m
//  OAuthConsumer
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
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


#import "OAMutableURLRequest.h"


@interface OAMutableURLRequest (Private)
- (void)_generateTimestamp;
- (void)_generateNonce;
- (NSString *)_signatureBaseString;
@end

@implementation OAMutableURLRequest
@synthesize signature, nonce;

#pragma mark init

- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding>)aProvider {
    if ((self = [super initWithURL:aUrl
           cachePolicy:NSURLRequestReloadIgnoringCacheData
	   timeoutInterval:10.0])) {
    
		consumer = [aConsumer retain];
		
		// empty token for Unauthorized Request Token transaction
		if (aToken == nil) {
			token = [[OAToken alloc] init];
		} else {
			token = [aToken retain];
		}
		
		if (aRealm == nil) {
			realm = @"";
		} else {
			realm = [aRealm copy];
		}
		  
		// default to HMAC-SHA1
		if (aProvider == nil) {
			signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
		} else {
			signatureProvider = [aProvider retain];
		}
		
		[self _generateTimestamp];
		[self _generateNonce];
        
        didPrepare = NO;
	}
    
    return self;
}

// Setting a timestamp and nonce to known
// values can be helpful for testing
- (id)initWithURL:(NSURL *)aUrl
		 consumer:(OAConsumer *)aConsumer
			token:(OAToken *)aToken
            realm:(NSString *)aRealm
signatureProvider:(id<OASignatureProviding>)aProvider
            nonce:(NSString *)aNonce
        timestamp:(NSString *)aTimestamp {
    if ((self = [self initWithURL:aUrl consumer:aConsumer token:aToken realm:aRealm signatureProvider:aProvider])) {
      nonce = [aNonce copy];
      timestamp = [aTimestamp copy];
    }
    
    return self;
}

- (void)setOAuthParameterName:(NSString*)parameterName withValue:(NSString*)parameterValue
{
	assert(parameterName && parameterValue);
    
	if (extraOAuthParameters == nil) {
		extraOAuthParameters = [NSMutableDictionary new];
	}
    
	[extraOAuthParameters setObject:parameterValue forKey:parameterName];
}

- (void)prepare {
    
    if (didPrepare) {
		return;
	}
	didPrepare = YES;
    
    // sign
//	NSLog(@"Base string is: %@", [self _signatureBaseString]);
   signature = [signatureProvider signClearText:[self _signatureBaseString]
                                      withSecret:[NSString stringWithFormat:@"%@&%@",
                                                  consumer.secret,
                                                  token.secret ? token.secret : @""]];
    
    // set OAuth headers
	NSMutableArray *chunks = [[NSMutableArray alloc] init];
	[chunks addObject:[NSString stringWithFormat:@"realm=\"%@\"", [realm encodedURLParameterString]]];
	[chunks addObject:[NSString stringWithFormat:@"oauth_consumer_key=\"%@\"", [consumer.key encodedURLParameterString]]];

	NSDictionary *tokenParameters = [token parameters];
	for (NSString *k in tokenParameters) {
		[chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", k, [[tokenParameters objectForKey:k] encodedURLParameterString]]];
	}
    

	[chunks addObject:[NSString stringWithFormat:@"oauth_signature_method=\"%@\"", [[signatureProvider name] encodedURLParameterString]]];
	[chunks addObject:[NSString stringWithFormat:@"oauth_signature=\"%@\"", [signature encodedURLParameterString]]];
	[chunks addObject:[NSString stringWithFormat:@"oauth_timestamp=\"%@\"", timestamp]];
	[chunks addObject:[NSString stringWithFormat:@"oauth_nonce=\"%@\"", nonce]];
	[chunks	addObject:@"oauth_version=\"1.0\""];
	
    
    // Adding the optional parameters in sorted order isn't required by the OAuth spec, but it makes it possible to hard-code expected values in the unit tests.
	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)])
	{
        [chunks addObject:[NSString stringWithFormat:@"%@=\"%@\"", parameterName, [[extraOAuthParameters objectForKey:parameterName] encodedURLParameterString]]];
	}
    
    
	NSString *oauthHeader = [NSString stringWithFormat:@"OAuth %@", [chunks componentsJoinedByString:@", "]];
	[chunks release];

    [self setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (void)_generateTimestamp {
	[timestamp release];
    timestamp = [[NSString alloc]initWithFormat:@"%ld", time(NULL)];
}

- (void)_generateNonce {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    [NSMakeCollectable(theUUID) autorelease];
	if (nonce) {
		CFRelease(nonce);
	}
    nonce = (NSString *)string;
}

NSInteger normalize(id obj1, id obj2, void *context)
{
    NSArray *nameAndValue1 = [obj1 componentsSeparatedByString:@"="];
    NSArray *nameAndValue2 = [obj2 componentsSeparatedByString:@"="];
    
    NSString *name1 = [nameAndValue1 objectAtIndex:0];
    NSString *name2 = [nameAndValue2 objectAtIndex:0];
    
// troppoli this was removed during a merge for tumblr
//    if (token.key.length > 0) {
//        [parameterPairs addObject:[[OARequestParameter requestParameterWithName:@"oauth_token" value:token.key] URLEncodedNameValuePair]];
    NSComparisonResult comparisonResult = [name1 compare:name2];
    if (comparisonResult == NSOrderedSame) {
        NSString *value1 = [nameAndValue1 objectAtIndex:1];
        NSString *value2 = [nameAndValue2 objectAtIndex:1];
        
        comparisonResult = [value1 compare:value2];
    }
    
    return comparisonResult;
}


- (NSString *)_signatureBaseString {
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
	NSDictionary *tokenParameters = [token parameters];
	// 6 being the number of OAuth params in the Signature Base String
	NSArray *parameters = [self parameters];
	NSMutableArray *parameterPairs = [[NSMutableArray alloc] initWithCapacity:(5 + [parameters count] + [tokenParameters count])];
    
	OARequestParameter *parameter;
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_consumer_key" value:consumer.key];
	
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_signature_method" value:[signatureProvider name]];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_timestamp" value:timestamp];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_nonce" value:nonce];
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	parameter = [[OARequestParameter alloc] initWithName:@"oauth_version" value:@"1.0"] ;
    [parameterPairs addObject:[parameter URLEncodedNameValuePair]];
	[parameter release];
	
	for(NSString *k in tokenParameters) {
		[parameterPairs addObject:[[OARequestParameter requestParameter:k value:[tokenParameters objectForKey:k]] URLEncodedNameValuePair]];
	}
    
// troppoli this vers was in the depot and was suserseeded by the merged version below, but I saw some comments about double URL encoding
// This might be a fix for that problem if it still exists.
//	for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
//		[parameterPairs addObject:[[OARequestParameter requestParameterWithName:parameterName value:[extraOAuthParameters objectForKey:parameterName]] URLEncodedNameValuePair]];
//	}
    for(NSString *parameterName in [[extraOAuthParameters allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		[parameterPairs addObject:[[OARequestParameter requestParameter:[parameterName encodedURLParameterString] value: [[extraOAuthParameters objectForKey:parameterName] encodedURLParameterString]] URLEncodedNameValuePair]];
	}
    
	if (![[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"]) {
		for (OARequestParameter *param in parameters) {
			[parameterPairs addObject:[param URLEncodedNameValuePair]];
		}
	}
    
    // Oauth Spec, Section 3.4.1.3.2 "Parameters Normalization    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingFunction:normalize context:NULL];

    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    [parameterPairs release];
	//	NSLog(@"Normalized: %@", normalizedRequestParameters);
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    return [NSString stringWithFormat:@"%@&%@&%@",
            [self HTTPMethod],
            [[[self URL] URLStringWithoutQuery] encodedURLParameterString],
            [normalizedRequestParameters encodedURLString]];
}

- (void) dealloc
{
    [consumer release];
	[token release];
	[signatureProvider release];
	[timestamp release];
    [extraOAuthParameters release];
	if (nonce) {
		CFRelease(nonce);
	}
	[super dealloc];
}

@end
