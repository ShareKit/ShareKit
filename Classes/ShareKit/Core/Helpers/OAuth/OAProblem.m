//
//  OAProblem.m
//  OAuthConsumer
//
//  Created by Alberto García Hierro on 03/09/08.
//  Copyright 2008 Alberto García Hierro. All rights reserved.
//	bynotes.com

#import "OAProblem.h"

NSString *signature_method_rejected = @"signature_method_rejected";
NSString *parameter_absent = @"parameter_absent";
NSString *version_rejected = @"version_rejected";
NSString *consumer_key_unknown = @"consumer_key_unknown";
NSString *token_rejected = @"token_rejected";
NSString *signature_invalid = @"signature_invalid";
NSString *nonce_used = @"nonce_used";
NSString *timestamp_refused = @"timestamp_refused";
NSString *token_expired = @"token_expired";
NSString *token_not_renewable = @"token_not_renewable";

@implementation OAProblem

@synthesize problem;

- (id)initWithPointer:(NSString *) aPointer
{
	if ((self = [super init])) {
		problem = [aPointer copy];
	}
	return self;
}

- (id)initWithProblem:(NSString *) aProblem
{
	NSUInteger idx = [[OAProblem validProblems] indexOfObject:aProblem];
	if (idx == NSNotFound) {
		return nil;
	}
	
	return [self initWithPointer: [[OAProblem validProblems] objectAtIndex:idx]];
}
	
- (id)initWithResponseBody:(NSString *) response
{
	NSArray *fields = [response componentsSeparatedByString:@"&"];
	for (NSString *field in fields) {
		if ([field hasPrefix:@"oauth_problem="]) {
			NSString *value = [[field componentsSeparatedByString:@"="] objectAtIndex:1];
			return [self initWithProblem:value];
		}
	}
	
	return nil;
}

- (void)dealloc
{
	[problem release];
	[super dealloc];
}

+ (OAProblem *)problemWithResponseBody:(NSString *) response
{
	return [[[OAProblem alloc] initWithResponseBody:response] autorelease];
}

+ (NSArray *)validProblems
{
	static NSArray *array;
	if (!array) {
		array = [[NSArray alloc] initWithObjects:signature_method_rejected,
										parameter_absent,
										version_rejected,
										consumer_key_unknown,
										token_rejected,
										signature_invalid,
										nonce_used,
										timestamp_refused,
										token_expired,
										token_not_renewable,
										nil];
	}
	
	return array;
}

- (BOOL)isEqualToProblem:(OAProblem *) aProblem
{
	return [problem isEqualToString:(NSString *)aProblem->problem];
}

- (BOOL)isEqualToString:(NSString *) aProblem
{
	return [problem isEqualToString:(NSString *)aProblem];
}

- (BOOL)isEqualTo:(id) aProblem
{
	if ([aProblem isKindOfClass:[NSString class]]) {
		return [self isEqualToString:aProblem];
	}
		
	if ([aProblem isKindOfClass:[OAProblem class]]) {
		return [self isEqualToProblem:aProblem];
	}
	
	return NO;
}

- (int)code {
	return [[[self class] validProblems] indexOfObject:problem];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"OAuth Problem: %@", (NSString *)problem];
}

#pragma mark class_methods

+ (OAProblem *)SignatureMethodRejected
{
	return [[[OAProblem alloc] initWithPointer:signature_method_rejected] autorelease];
}

+ (OAProblem *)ParameterAbsent
{
	return [[[OAProblem alloc] initWithPointer:parameter_absent] autorelease];
}

+ (OAProblem *)VersionRejected
{
	return [[[OAProblem alloc] initWithPointer:version_rejected] autorelease];
}

+ (OAProblem *)ConsumerKeyUnknown
{
	return [[[OAProblem alloc] initWithPointer:consumer_key_unknown] autorelease];
}

+ (OAProblem *)TokenRejected
{
	return [[[OAProblem alloc] initWithPointer:token_rejected] autorelease];
}

+ (OAProblem *)SignatureInvalid
{
	return [[[OAProblem alloc] initWithPointer:signature_invalid] autorelease];
}

+ (OAProblem *)NonceUsed
{
	return [[[OAProblem alloc] initWithPointer:nonce_used] autorelease];
}

+ (OAProblem *)TimestampRefused
{
	return [[[OAProblem alloc] initWithPointer:timestamp_refused] autorelease];
}

+ (OAProblem *)TokenExpired
{
	return [[[OAProblem alloc] initWithPointer:token_expired] autorelease];
}

+ (OAProblem *)TokenNotRenewable
{
	return [[[OAProblem alloc] initWithPointer:token_not_renewable] autorelease];
}
					  
@end
