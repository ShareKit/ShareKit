//
//  SHKVKontakteRequest.m
//  ShareKit
//
//  Created by user on 11.12.12.
//
//

#import "SHKVKontakteRequest.h"

#define SHK_TIMEOUT 90

@implementation SHKVKontakteRequest


- (id)initWithURL:(NSURL *)u paramsData:(NSData *)pD method:(NSString *)m completion:(RequestCallback)completionBlock
{
	self = [super initWithURL:u params:nil method:m completion:completionBlock];
    if (self)
	{
		_paramsData = pD;
    }
	return self;
}

#pragma mark -

- (void)start
{
	NSMutableData *aData = [[NSMutableData alloc] initWithLength:0];
    self.data = aData;
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:SHK_TIMEOUT];
	
	// overwrite header fields (generally for cookies)
	if (self.headerFields != nil)
		[request setAllHTTPHeaderFields:self.headerFields];
	
	// Setup Request Data/Params
	if (self.paramsData != nil)
	{
		// Fill Request
		[request setHTTPMethod:self.method];
		[request setHTTPBody:self.paramsData];
    } else
        if (self.params != nil)
        {
            NSData *requestParamsData = [ NSData dataWithBytes:[self.params UTF8String] length:[self.params length] ];
            
            // Fill Request
            [request setHTTPMethod:self.method];
            [request setHTTPBody:requestParamsData];
        }
	
	// Start Connection
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.connection = aConnection;	
}


@end
