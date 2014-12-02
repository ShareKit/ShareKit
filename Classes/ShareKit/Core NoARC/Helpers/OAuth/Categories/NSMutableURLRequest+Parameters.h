//
//  NSMutableURLRequest+Parameters.h
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

#import <Foundation/Foundation.h>

@class SHKFile;


@interface NSMutableURLRequest (OAParameterAdditions)

- (NSArray *)parameters;
- (void)setParameters:(NSArray *)parameters;

///The method resolves, if file hasPath or hasData. If has path, it is streamed via NSInputStream - thus the file is not read into memory. If hasData, it is packed directly within body's request. Preferred method for attaching files (over attachFileWithParameterName:filename:contentType:data:).
- (void)attachFile:(SHKFile *)file withParameterName:(NSString *)name;

///This method attaches data directly to request's httpBody. If not present, prepares one.
- (void)attachData:(NSData *)data withParameterName:(NSString *)parameterName contentType:(NSString *)contentType;

///Fallback method for services, which are not able to handle NSInputStream type of multipart/form-data request without "Content-Length". It is a bug (or a feature) of NSURLSession that it discards original request's "Content-Length" header. For more info see https://devforums.apple.com/message/919330#919330 or https://github.com/AFNetworking/AFNetworking/issues/1398  In other words, all services, which encounter http error "411 Length Required" should use this method instead of attachFile:WithParameterName. Unfortunately, using this method shared file has to be read into memory.
- (void)attachFileWithParameterName:(NSString *)name filename:(NSString*)filename contentType:(NSString *)contentType data:(NSData*)data;

@end
