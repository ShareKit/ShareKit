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

@synthesize paramsData;

- (void)dealloc
{
    [paramsData release];
	[super dealloc];
}


- (id)initWithURL:(NSURL *)u paramsData:(NSData *)pD delegate:(id)d isFinishedSelector:(SEL)s method:(NSString *)m autostart:(BOOL)autostart
{
	if (self = [super init])
	{
		self.url = u;
		self.paramsData = pD;
		self.method = m;
		
		self.delegate = d;
		self.isFinishedSelector = s;
		
		if (autostart)
			[self start];
	}
	
	return self;
}


#pragma mark -

- (void)start
{
	NSMutableData *aData = [[NSMutableData alloc] initWithLength:0];
    self.data = aData;
	[aData release];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                            timeoutInterval:SHK_TIMEOUT];
	
	// overwrite header fields (generally for cookies)
	if (headerFields != nil)
		[request setAllHTTPHeaderFields:headerFields];
	
	// Setup Request Data/Params
	if (paramsData != nil)
	{
		// Fill Request
		[request setHTTPMethod:method];
		[request setHTTPBody:paramsData];
    } else
        if (params != nil)
        {
            NSData *requestParamsData = [ NSData dataWithBytes:[params UTF8String] length:[params length] ];
            
            // Fill Request
            [request setHTTPMethod:method];
            [request setHTTPBody:requestParamsData];
        }
	
	// Start Connection
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    [request release];
    self.connection = aConnection;	
	[aConnection release];
}


@end
