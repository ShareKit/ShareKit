//
//  OATokenManager.h
//  OAuthConsumer
//
//  Created by Alberto García Hierro on 01/09/08.
//  Copyright 2008 Alberto García Hierro. All rights reserved.
//	bynotes.com

#import <Foundation/Foundation.h>

#import "OACall.h"

@class OATokenManager;

@protocol OATokenManagerDelegate

- (BOOL)tokenManager:(OATokenManager *)manager failedCall:(OACall *)call withError:(NSError *)error;
- (BOOL)tokenManager:(OATokenManager *)manager failedCall:(OACall *)call withProblem:(OAProblem *)problem;

@optional

- (BOOL)tokenManagerNeedsToken:(OATokenManager *)manager;

@end

@class OAConsumer;
@class OAToken;

@interface OATokenManager : NSObject<OACallDelegate> {
	OAConsumer *consumer;
	OAToken *acToken;
	OAToken *reqToken;
	OAToken *initialToken;
	NSString *authorizedTokenKey;
	NSString *oauthBase;
	NSString *realm;
	NSString *callback;
	NSObject <OATokenManagerDelegate> *delegate;
	NSMutableArray *calls;
	NSMutableArray *selectors;
	NSMutableDictionary *delegates;
	BOOL isDispatching;
}


- (id)init;

- (id)initWithConsumer:(OAConsumer *)aConsumer token:(OAToken *)aToken oauthBase:(const NSString *)base
				 realm:(const NSString *)aRealm callback:(const NSString *)aCallback
			  delegate:(NSObject <OATokenManagerDelegate> *)aDelegate;

- (void)authorizedToken:(const NSString *)key;

- (void)fetchData:(NSString *)aURL finished:(SEL)didFinish;

- (void)fetchData:(NSString *)aURL method:(NSString *)aMethod parameters:(NSArray *)theParameters
		 finished:(SEL)didFinish;

- (void)fetchData:(NSString *)aURL method:(NSString *)aMethod parameters:(NSArray *)theParameters
			files:(NSDictionary *)theFiles finished:(SEL)didFinish;

- (void)fetchData:(NSString *)aURL method:(NSString *)aMethod parameters:(NSArray *)theParameters
			files:(NSDictionary *)theFiles finished:(SEL)didFinish delegate:(NSObject*)aDelegate;

- (void)call:(OACall *)call failedWithError:(NSError *)error;
- (void)call:(OACall *)call failedWithProblem:(OAProblem *)problem;

@end
