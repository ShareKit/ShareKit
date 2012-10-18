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

static NSString *Boundary = @"-----------------------------------0xCoCoaouTHeBouNDaRy"; 

@implementation NSMutableURLRequest (OAParameterAdditions)

- (BOOL)isMultipart {
	return [[self valueForHTTPHeaderField:@"Content-Type"] hasPrefix:@"multipart/form-data"];
}

- (NSArray *)parameters {
    NSString *encodedParameters = nil;
    
	if (![self isMultipart]) {
		if ([[self HTTPMethod] isEqualToString:@"GET"] || [[self HTTPMethod] isEqualToString:@"DELETE"]) {
			encodedParameters = [[self URL] query];
		} else {
			encodedParameters = [[[NSString alloc] initWithData:[self HTTPBody] encoding:NSASCIIStringEncoding] autorelease];
		}
	}
    
    if (encodedParameters == nil || [encodedParameters isEqualToString:@""]) {
        return nil;
    }
//    NSLog(@"raw parameters %@", encodedParameters);
    NSArray *encodedParameterPairs = [encodedParameters componentsSeparatedByString:@"&"];
    NSMutableArray *requestParameters = [NSMutableArray arrayWithCapacity:[encodedParameterPairs count]];
    
    for (NSString *encodedPair in encodedParameterPairs) {
        NSArray *encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
        OARequestParameter *parameter = [[OARequestParameter alloc] initWithName:[[encodedPairElements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                                           value:[[encodedPairElements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [requestParameters addObject:parameter];
		[parameter release];
    }
    
    return requestParameters;
}

- (void)setParameters:(NSArray *)parameters
{
	NSMutableArray *pairs = [[[NSMutableArray alloc] initWithCapacity:[parameters count]] autorelease];
	for (OARequestParameter *requestParameter in parameters) {
		[pairs addObject:[requestParameter URLEncodedNameValuePair]];
	}
	
	NSString *encodedParameterPairs = [pairs componentsJoinedByString:@"&"];
    
	if ([[self HTTPMethod] isEqualToString:@"GET"] || [[self HTTPMethod] isEqualToString:@"DELETE"]) {
		[self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [[self URL] URLStringWithoutQuery], encodedParameterPairs]]];
	} else {
		// POST, PUT
		[self setHTTPBodyWithString:encodedParameterPairs];
		[self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	}
}

- (void)setHTTPBodyWithString:(NSString *)body {
	NSData *bodyData = [body dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	[self setValue:[NSString stringWithFormat:@"%d", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
	[self setHTTPBody:bodyData];
}

- (void)attachFileWithName:(NSString *)name filename:(NSString*)filename contentType:(NSString *)contentType data:(NSData*)data {

	NSArray *parameters = [self parameters];
	[self setValue:[@"multipart/form-data; boundary=" stringByAppendingString:Boundary] forHTTPHeaderField:@"Content-type"];
	
	NSMutableData *bodyData = [NSMutableData new];
	for (OARequestParameter *parameter in parameters) {
		NSString *param = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n",
						   Boundary, [parameter URLEncodedName], [parameter value]];

		[bodyData appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
	}

	NSString *filePrefix = [NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n",
		Boundary, name, filename, contentType];
	[bodyData appendData:[filePrefix dataUsingEncoding:NSUTF8StringEncoding]];
	[bodyData appendData:data];
	
	[bodyData appendData:[[[@"\r\n--" stringByAppendingString:Boundary] stringByAppendingString:@"--"] dataUsingEncoding:NSUTF8StringEncoding]];
	[self setValue:[NSString stringWithFormat:@"%d", [bodyData length]] forHTTPHeaderField:@"Content-Length"];
	[self setHTTPBody:bodyData];
	[bodyData release];
}

@end
