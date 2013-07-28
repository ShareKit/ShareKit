//
//  SHKRequest.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/9/10.

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

#import "SHKRequest.h"
#import "Debug.h"

#define SHK_TIMEOUT 90

@interface SHKRequest ()

@property (copy) RequestCallback completion;

@end

@implementation SHKRequest

+ (void)startWithURL:(NSURL *)u params:(NSString *)p method:(NSString *)m completion:(RequestCallback)completionBlock {
    
    id request = [[self alloc] initWithURL:u params:p method:m completion:completionBlock];
    [(SHKRequest *)request start];
}

- (id)initWithURL:(NSURL *)u params:(NSString *)p method:(NSString *)m completion:(RequestCallback)completionBlock
{
	if (self = [super init])
	{
		_url = u;
		_params = p;
		_method = m;
        _completion = completionBlock;
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
	if (self.params != nil)
	{
		NSData *paramsData = [ NSData dataWithBytes:[self.params UTF8String] length:[self.params length] ];
		
		// Fill Request
		[request setHTTPMethod:self.method];
		[request setHTTPBody:paramsData];
	}
	
	// Start Connection
	SHKLog(@"Start SHKRequest:\nURL: %@\nparams: %@", self.url, self.params);
	NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.connection = aConnection;	
}


#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)theResponse 
{
	self.response = theResponse;
	NSDictionary *aHeaders = [[self.response allHeaderFields] mutableCopy];
	self.headers = aHeaders;
	
	[self.data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d 
{
	[self.data appendData:d];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
	[self finish];
}

#pragma mark -

- (void)finish
{
	self.success = (self.response.statusCode == 200 || self.response.statusCode == 201);
    self.completion(self);
}

- (NSString *)getResult
{
	if (_result == nil)
		_result = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
	return _result;
}

#pragma mark -

- (NSString *)description {
    
    NSString *functionResult = [NSString stringWithFormat:@"method: %@\nurl: %@\nparams: %@\nresponse: %i (%@)\ndata: %@", self.method, [self.url absoluteString], self.params, [self.response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[self.response statusCode]], [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding]];
    
    return functionResult;    
}

@end
