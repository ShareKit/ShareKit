//
//  SHKHatena.m
//  ShareKit
//
//  Created by kishikawa katsumi on 2012/09/04.
//
//

#import "SHKHatena.h"
#import "SharersCommonHeaders.h"
#import "NSString+URLEncoding.h"

NSString * const kSHKHatenaUserInfo = @"kSHKHatenaUserInfo";

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

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Hatena"); }

+ (BOOL)canShareURL { return YES; }
+ (BOOL)canGetUserInfo { return YES; }

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKHatenaUserInfo];
    NSString *result = userInfo[@"display_name"];
    return result;
}

+ (void)logout {
    
    [super logout];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKHatenaUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

- (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
{
    [oRequest setOAuthParameterName:@"oauth_callback" withValue:[self.authorizeCallbackURL absoluteString]];
    oRequest.parameters = @[[OARequestParameter requestParameterWithName:@"scope" value:SHKCONFIG(hatenaScope)]];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
    [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[[authorizeResponseQueryVars objectForKey:@"oauth_verifier"] URLDecodedString]];
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
    OAMutableURLRequest *oRequest;
    if ([self validateItem] && self.item.shareType == SHKShareTypeURL) {
        
        oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://b.hatena.ne.jp/atom/post"]
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
        
    } else if (self.item.shareType == SHKShareTypeUserInfo) {
        
        self.quiet = YES;
        oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://n.hatena.com/applications/my.json"]
                                                   consumer:consumer
                                                      token:accessToken
                                                      realm:nil
                                          signatureProvider:signatureProvider];
    } else {
        
        return NO;
    }

    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
    [fetcher start];
    [self sendDidStart];
    
    return YES;
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed && ticket.response.statusCode == 201) {

        [self sendDidFinish];
        
    } else if (ticket.didSucceed && ticket.response.statusCode == 200) {
       
        NSError *error;
        NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKHatenaUserInfo];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
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
