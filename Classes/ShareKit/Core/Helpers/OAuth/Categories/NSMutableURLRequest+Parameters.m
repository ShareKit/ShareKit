//
//  NSMutableURLRequest+Parameters.m
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


#import "NSMutableURLRequest+Parameters.h"

#import "PKMultipartInputStream.h"
#import "SHKFile.h"
#import "OARequestParameter.h"
#import "OAMutableURLRequest.h"

#import "NSURL+Base.h"

static NSString *Boundary = @"----------0xCoCoaouTHeBouNDaRy";

@implementation NSMutableURLRequest (OAParameterAdditions)

- (NSArray *)parameters 
{
    NSString *encodedParameters;
	BOOL shouldfree = NO;
    
    if ([[self HTTPMethod] isEqualToString:@"GET"] || [[self HTTPMethod] isEqualToString:@"DELETE"]) 
        encodedParameters = [[self URL] query];
	else 
	{
        // POST, PUT
		shouldfree = YES;
        encodedParameters = [[NSString alloc] initWithData:[self HTTPBody] encoding:NSASCIIStringEncoding];
    }
    
    if ((encodedParameters == nil) || ([encodedParameters isEqualToString:@""]))
	{
		if (shouldfree)
			[encodedParameters release];
		
        return nil;
	}
    
    NSArray *encodedParameterPairs = [encodedParameters componentsSeparatedByString:@"&"];
    NSMutableArray *requestParameters = [[[NSMutableArray alloc] initWithCapacity:16] autorelease];
    
    for (NSString *encodedPair in encodedParameterPairs) 
	{
        NSArray *encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
        OARequestParameter *parameter = [OARequestParameter requestParameterWithName:[[encodedPairElements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
																			   value:[[encodedPairElements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [requestParameters addObject:parameter];
    }
    
	// Cleanup
	if (shouldfree)
		[encodedParameters release];
	
    return requestParameters;
}

- (void)setParameters:(NSArray *)parameters 
{
    NSMutableString *encodedParameterPairs = [NSMutableString stringWithCapacity:256];
    
    NSUInteger position = 1;
    for (OARequestParameter *requestParameter in parameters) 
	{
        [encodedParameterPairs appendString:[requestParameter URLEncodedNameValuePair]];
        if (position < [parameters count])
            [encodedParameterPairs appendString:@"&"];
		
        position++;
    }
    
    if ([[self HTTPMethod] isEqualToString:@"GET"] || [[self HTTPMethod] isEqualToString:@"DELETE"])
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [[self URL] URLStringWithoutQuery], encodedParameterPairs]]];
    else 
	{
        // POST, PUT
        NSData *postData = [encodedParameterPairs dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[postData length]] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
}

//inspired by https://github.com/jdg/oauthconsumer/
- (void)attachFileWithParameterName:(NSString *)name filename:(NSString*)filename contentType:(NSString *)contentType data:(NSData*)data {
    
    NSMutableData *bodyData = [self preparedBodyData];
    
    [self setValue:[@"multipart/form-data; boundary=" stringByAppendingString:Boundary] forHTTPHeaderField:@"Content-type"];
    
	NSString *filePrefix = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n", Boundary, name, filename, contentType];
	[bodyData appendData:[filePrefix dataUsingEncoding:NSUTF8StringEncoding]];
    
	[bodyData appendData:data];
    
	[bodyData appendData:[[[@"\r\n--" stringByAppendingString:Boundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    
    [self setHTTPBody:bodyData];
}

- (void)attachData:(NSData *)data withParameterName:(NSString *)parameterName contentType:(NSString *)contentType {
    
    NSMutableData *bodyData = [self preparedBodyData];
    
    [self setValue:[@"multipart/form-data; boundary=" stringByAppendingString:Boundary] forHTTPHeaderField:@"Content-type"];
    
    NSString *dataPrefix = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\nContent-Type: %@\r\n\r\n", Boundary, parameterName, contentType];
    [bodyData appendData:[dataPrefix dataUsingEncoding:NSUTF8StringEncoding]];
    [bodyData appendData:data];
    
    [bodyData appendData:[[[@"\r\n--" stringByAppendingString:Boundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
	[self setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]] forHTTPHeaderField:@"Content-Length"];
	[self setHTTPBody:bodyData];
}

- (NSMutableData *)preparedBodyData {
    
    NSMutableData *result;
    
    if (self.HTTPBody) {
        
        result = (NSMutableData *)self.HTTPBody;
        
        NSString *trailingBoundary = [[[NSString alloc] initWithFormat:@"--%@--", Boundary] autorelease];
        NSString *bodyString = [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease];
        
        //if trailing boundary already present, remove it
        if ([bodyString hasSuffix:trailingBoundary]) {
            NSString *trimmedBodyString = [bodyString substringToIndex:[result length]-[trailingBoundary length]];
            result = [[trimmedBodyString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            [result autorelease];
            
        } else {
            
            //assume the body contains plain oauth parameters only. We need to convert them to multipart/form-data. It is a hacky workaround due to legacy sharers. It is easier to do it here than change all sharer's code.
            result = [self convertParamsToMultipartData];
        }

    } else {
        
        result = [self convertParamsToMultipartData];
    }
    
    return result;
}

- (NSMutableData *)convertParamsToMultipartData {
    
    NSMutableData *result = [[NSMutableData new] autorelease];

    //for oauth parameters only
    NSArray *parameters = [self parameters];
    for (OARequestParameter *parameter in parameters) {
        NSString *param = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", Boundary, [parameter URLEncodedName], [parameter value]];
        
        [result appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return result;
}

- (void)attachFile:(SHKFile *)file withParameterName:(NSString *)name {
    
    if ([file hasPath]) {
        
        PKMultipartInputStream *body = [self preparedStream];
        [body addPartWithName:name path:file.path];
        
        [self setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
        [self setHTTPBodyStream:body];

    } else {
        
        [self attachFileWithParameterName:name filename:file.filename contentType:file.mimeType data:file.data];
    }
}

- (PKMultipartInputStream *)preparedStream {
    
    PKMultipartInputStream *result = [[[PKMultipartInputStream alloc] init] autorelease];
    
    // for oauth parameters only
    NSArray *parameters = [self parameters];
    for (OARequestParameter *parameter in parameters) {
        [result addPartWithName:[parameter URLEncodedName] string:[parameter value]];
    }
    
    [self setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [result boundary]] forHTTPHeaderField:@"Content-Type"];
    
    return result;
}

@end
