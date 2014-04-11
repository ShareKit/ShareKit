//
//  SHKRequest.h
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

#import <Foundation/Foundation.h>

@class SHKRequest;

typedef void (^RequestCallback) (SHKRequest *request);

@interface SHKRequest : NSObject

///You can set this prior starting the request if needed
@property (nonatomic, strong) NSDictionary *headerFields;

@property (readonly, strong) NSURL *url;
@property (readonly, strong) NSString *params;
@property (readonly, strong) NSString *method;

@property (strong) NSURLConnection *connection;

//*** response properties ***
@property (strong) NSHTTPURLResponse *response;
@property (strong) NSDictionary *headers;

@property (strong) NSMutableData *data;
@property (nonatomic, strong, getter=getResult) NSString *result;
@property (nonatomic) BOOL success;

+ (void)startWithURL:(NSURL *)u params:(NSString *)p method:(NSString *)m completion:(RequestCallback)completionBlock;
- (instancetype)initWithURL:(NSURL *)u params:(NSString *)p method:(NSString *)m completion:(RequestCallback)completionBlock;

+ (void)startWithRequest:(NSMutableURLRequest *)request completion:(RequestCallback)completionBlock;
- (instancetype)initWithRequest:(NSMutableURLRequest *)request completion:(RequestCallback)completionBlock;

- (void)start;
- (void)finish;

@end
