//
//  SHKHatena.m
//  ShareKit
//
//  Created by kishikawa katsumi on 2012/09/04.
//
//

#import "SHKHatena.h"
#import "SHKXMLResponseParser.h"
#import "SharersCommonHeaders.h"

@interface SHKHatena ()

@end

@implementation SHKHatena

- (id)init
{
	if (self = [super init])
	{
		// OAUTH
		self.consumerKey = SHKCONFIG(hatenaConsumerKey);
		self.secretKey = SHKCONFIG(hatenaSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:@"http://www.example.com/"];
		
		
		// -- //
		
		
		// You do not need to edit these, they are the same for everyone
        self.requestURL = [NSURL URLWithString:@"https://www.hatena.com/oauth/initiate"];
        self.authorizeURL = [NSURL URLWithString:@"https://www.hatena.com/touch/oauth/authorize"];
        self.accessURL = [NSURL URLWithString:@"https://www.hatena.com/oauth/token"];
	}
	return self;
}

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Hatena");
}

+ (BOOL)canShareURL
{
	return YES;
}

#pragma mark -

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
    [oRequest setOAuthParameterName:@"oauth_callback" withValue:[self.authorizeCallbackURL absoluteString]];
    oRequest.parameters = @[[OARequestParameter requestParameterWithName:@"scope" value:SHKCONFIG(hatenaScope)]];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
    [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}

#pragma mark -

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	if (type == SHKShareTypeURL) {
		return @[[SHKFormFieldSettings label:SHKLocalizedString(@"Comment") key:@"text" type:SHKFormFieldTypeText start:self.item.text]];
	}
	return nil;
}

#pragma mark -

- (BOOL)send
{
    if ([self validateItem] && self.item.shareType == SHKShareTypeURL) {
        OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://b.hatena.ne.jp/atom/post"]
                                                                        consumer:consumer
                                                                           token:accessToken
                                                                           realm:nil
                                                               signatureProvider:signatureProvider];
        [oRequest setHTTPMethod:@"POST"];
        [oRequest prepare];
        
        NSString *body = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                          @"<entry xmlns=\"http://purl.org/atom/ns#\">"
                          @"<link rel=\"related\" type=\"text/html\" href=\"%@\" />"
                          @"<summary type=\"text/plain\">%@</summary>"
                          @"</entry>", self.item.URL, self.item.text ?: @""];
        [oRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [oRequest setValue:@"text/xml;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        
        OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                              delegate:self
                                                                                     didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                       didFailSelector:@selector(sendTicket:didFailWithError:)];
        [fetcher start];
        
        [self sendDidStart];
        
        return YES;
    }
    
    return NO;
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed && ticket.response.statusCode == 201) {
        [self sendDidFinish];
    } else {
        SHKLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        
        if (ticket.response.statusCode == 401) {
            [self shouldReloginWithPendingAction:SHKPendingSend];
        } else {
            [self sendShowSimpleErrorAlert];
        }
    }
}

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError *)error
{
    [self sendDidFailWithError:error shouldRelogin:NO];
}

@end
