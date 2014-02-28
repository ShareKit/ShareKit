//
//  SHKSession.m
//  ShareKit
//
//  Created by Vilem Kurz on 25/02/2014.
//
//

#import "SHKSession.h"

#import "Debug.h"
#import "SHKSessionDelegate.h"

@interface SHKSession ()

@property (strong, nonatomic) NSURLSession *uploadSession;
@property (strong, nonatomic) NSURLSessionDataTask *dataTask;
@property (weak, nonatomic) id <SHKSessionDelegate> delegate;

@end

@implementation SHKSession

+ (instancetype)startSessionWithRequest:(NSURLRequest *)request delegate:(id <SHKSessionDelegate>)delegate completion:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completion {
    
    SHKSession *result = [[SHKSession alloc] init];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.HTTPMaximumConnectionsPerHost = 1;
    result.uploadSession = [NSURLSession sessionWithConfiguration:config
                                                       delegate:result
                                                  delegateQueue:[NSOperationQueue mainQueue]];
    result.dataTask = [result.uploadSession dataTaskWithRequest:request completionHandler:completion];
    result.delegate = delegate;
    [result.dataTask resume];
    
    [result.uploadSession finishTasksAndInvalidate]; //to get rid of the session after finishing upload
    
    return result;
}

- (void)cancel {
    
    [self.dataTask cancel];
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
    [self.delegate showUploadedBytes:totalBytesSent totalBytes:totalBytesExpectedToSend];
}
/*
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    SHKLog(@"session task did complete with error");
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    SHKLog(@"session task did receive response");
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    SHKLog(@"session task did receive data");
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    SHKLog(@"session did become invalid");
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}*/

@end
