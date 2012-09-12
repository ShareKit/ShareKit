//
//  OAToken.m
//  OAuthConsumer
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


#import "NSString+URLEncoding.h"
#import "OAToken.h"

@interface OAToken (Private)

+ (NSString *)settingsKey:(const NSString *)name provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (id)loadSetting:(const NSString *)name provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (void)saveSetting:(NSString *)name object:(id)object provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (NSNumber *)durationWithString:(NSString *)aDuration;
+ (NSDictionary *)attributesWithString:(NSString *)theAttributes;

@end

@implementation OAToken

@synthesize key, secret, session, duration, verifier, attributes, forRenewal;

#pragma mark init

- (id)init {
	return [self initWithKey:nil secret:nil];
}

- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret {
	return [self initWithKey:aKey secret:aSecret session:nil duration:nil
				  attributes:nil created:nil renewable:NO];
}

- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret session:(NSString *)aSession
		 duration:(NSNumber *)aDuration attributes:(NSDictionary *)theAttributes created:(NSDate *)creation
		renewable:(BOOL)renew {
	if ((self = [super init])) {
		self.key = aKey;
		self.secret = aSecret;
		self.session = aSession;
		self.duration = aDuration;
		self.attributes = theAttributes;
		created = [creation retain];
		renewable = renew;
		forRenewal = NO;
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	OAToken *t = [self initWithKey:[aDecoder decodeObjectForKey:@"key"]
							secret:[aDecoder decodeObjectForKey:@"secret"]
						   session:[aDecoder decodeObjectForKey:@"session"]
						  duration:[aDecoder decodeObjectForKey:@"duration"]
						attributes:[aDecoder decodeObjectForKey:@"attributes"]
						   created:[aDecoder decodeObjectForKey:@"created"]
						 renewable:[aDecoder decodeBoolForKey:@"renewable"]];
	[t setVerifier:[aDecoder decodeObjectForKey:@"verifier"]];
	return t;
}

- (id)initWithHTTPResponseBody:(const NSString *)body {
    NSString *aKey = nil;
	NSString *aSecret = nil;
	NSString *aSession = nil;
	NSNumber *aDuration = nil;
	NSDate *creationDate = nil;
	NSDictionary *attrs = nil;
	BOOL renew = NO;
	NSArray *pairs = [body componentsSeparatedByString:@"&"];

	for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token"]) {
            aKey = [elements objectAtIndex:1];
        } else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_secret"]) {
            aSecret = [elements objectAtIndex:1];
        } else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_session_handle"]) {
			aSession = [elements objectAtIndex:1];
		} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_duration"]) {
			aDuration = [[self class] durationWithString:[elements objectAtIndex:1]];
			creationDate = [NSDate date];
		} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_attributes"]) {
			attrs = [[self class] attributesWithString:[[elements objectAtIndex:1] decodedURLString]];
		} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_renewable"]) {
			NSString *lowerCase = [[elements objectAtIndex:1] lowercaseString];
			if ([lowerCase isEqualToString:@"true"] || [lowerCase isEqualToString:@"t"]) {
				renew = YES;
			}
		}
    }
    
    return [self initWithKey:aKey secret:aSecret session:aSession duration:aDuration
				  attributes:attrs created:creationDate renewable:renew];
}

- (id)initWithUserDefaultsUsingServiceProviderName:(const NSString *)provider prefix:(const NSString *)prefix {
	if ((self = [super init])) {
      self.key = [OAToken loadSetting:@"key" provider:provider prefix:prefix];
      self.secret = [OAToken loadSetting:@"secret" provider:provider prefix:prefix];
      self.session = [OAToken loadSetting:@"session" provider:provider prefix:prefix];
      self.duration = [OAToken loadSetting:@"duration" provider:provider prefix:prefix];
      self.attributes = [OAToken loadSetting:@"attributes" provider:provider prefix:prefix];
      created = [OAToken loadSetting:@"created" provider:provider prefix:prefix];
      renewable = [[OAToken loadSetting:@"renewable" provider:provider prefix:prefix] boolValue];

      if (![self isValid]) {
        [self autorelease];
        return nil;
      }
  }
	
	return self;
}

#pragma mark dealloc

- (void)dealloc {
    self.key = nil;
    self.secret = nil;
	self.session = nil;
    self.duration = nil;
    self.verifier = nil;
    self.attributes = nil;
	[super dealloc];
}

#pragma mark settings

- (BOOL)isValid {
	return (key != nil && ![key isEqualToString:@""] && secret != nil && ![secret isEqualToString:@""]);
}

- (int)storeInUserDefaultsWithServiceProviderName:(const NSString *)provider prefix:(const NSString *)prefix {
	[OAToken saveSetting:@"key" object:key provider:provider prefix:prefix];
	[OAToken saveSetting:@"secret" object:secret provider:provider prefix:prefix];
	[OAToken saveSetting:@"created" object:created provider:provider prefix:prefix];
	[OAToken saveSetting:@"duration" object:duration provider:provider prefix:prefix];
	[OAToken saveSetting:@"session" object:session provider:provider prefix:prefix];
	[OAToken saveSetting:@"attributes" object:attributes provider:provider prefix:prefix];
	[OAToken saveSetting:@"renewable" object:renewable ? @"t" : @"f" provider:provider prefix:prefix];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	return(0);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self key] forKey:@"key"];
	[aCoder encodeObject:[self secret] forKey:@"secret"];
	[aCoder encodeObject:[self session] forKey:@"session"];
	[aCoder encodeObject:[self duration] forKey:@"duration"];
	[aCoder encodeObject:[self attributes] forKey:@"attributes"];
	[aCoder encodeBool:renewable forKey:@"renewable"];
	[aCoder encodeObject:[self verifier] forKey:@"verifier"];
}

#pragma mark duration

- (void)setDurationWithString:(NSString *)aDuration {
	self.duration = [[self class] durationWithString:aDuration];
}

- (BOOL)hasExpired
{
	return created && [created timeIntervalSinceNow] > [duration intValue];
}

- (BOOL)isRenewable
{
	return session && renewable && created && [created timeIntervalSinceNow] < (2 * [duration intValue]);
}


#pragma mark attributes

- (void)setAttribute:(const NSString *)aKey value:(const NSString *)aAttribute {
	if (!attributes) {
		attributes = [[NSMutableDictionary alloc] init];
	}
	[attributes setObject: aAttribute forKey: aKey];
}

- (void)setAttributes:(NSDictionary *)theAttributes {
	[attributes release];
	if (theAttributes) {
		attributes = [[NSMutableDictionary alloc] initWithDictionary:theAttributes];
	}else {
		attributes = nil;
	}
	
}

- (BOOL)hasAttributes {
	return (attributes && [attributes count] > 0);
}

- (NSString *)attributeString {
	if (![self hasAttributes]) {
		return @"";
	}
	
	NSMutableArray *chunks = [[NSMutableArray alloc] init];
	for(NSString *aKey in self->attributes) {
		[chunks addObject:[NSString stringWithFormat:@"%@:%@", aKey, [attributes objectForKey:aKey]]];
	}
	NSString *attrs = [chunks componentsJoinedByString:@";"];
	[chunks release];
	return attrs;
}

- (NSString *)attribute:(NSString *)aKey
{
	return [attributes objectForKey:aKey];
}

- (void)setAttributesWithString:(NSString *)theAttributes
{
	self.attributes = [[self class] attributesWithString:theAttributes];
}

- (NSDictionary *)parameters
{
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];

	if (key) {
		[params setObject:key forKey:@"oauth_token"];
		if ([self isForRenewal]) {
			[params setObject:session forKey:@"oauth_session_handle"];
		}
	} else {
		if (duration) {
			[params setObject:[duration stringValue] forKey: @"oauth_token_duration"];
		}
		if ([attributes count]) {
			[params setObject:[self attributeString] forKey:@"oauth_token_attributes"];
		}
	}
	if (self.verifier) {
		[params setObject:self.verifier forKey:@"oauth_verifier"];
	}
	return params;
}

#pragma mark comparisions

- (BOOL)isEqual:(id)object {
	if([object isKindOfClass:[self class]]) {
		return [self isEqualToToken:(OAToken *)object];
	}
	return NO;
}

- (BOOL)isEqualToToken:(OAToken *)aToken {
	/* Since ScalableOAuth determines that the token may be
	 renewed using the same key and secret, we must also
	 check the creation date */
	if ([self.key isEqualToString:aToken.key] &&
		[self.secret isEqualToString:aToken.secret]) {
		/* May be nil */
		if (created == aToken->created || [created isEqualToDate:aToken->created]) {
			return YES;
		}
	}
	
	return NO;
}
			
#pragma mark class_functions
			
+ (NSString *)settingsKey:(NSString *)name provider:(NSString *)provider prefix:(NSString *)prefix {
	return [NSString stringWithFormat:@"OAUTH_%@_%@_%@", provider, prefix, [name uppercaseString]];
}
			
+ (id)loadSetting:(NSString *)name provider:(NSString *)provider prefix:(NSString *)prefix {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self settingsKey:name
																		provider:provider
																		  prefix:prefix]];
}
			
+ (void)saveSetting:(NSString *)name object:(id)object provider:(NSString *)provider prefix:(NSString *)prefix {
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:[self settingsKey:name
																			provider:provider
																			  prefix:prefix]];
}
	
+ (void)removeFromUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix {
	NSArray *keys = [NSArray arrayWithObjects:@"key", @"secret", @"created", @"duration", @"session", @"attributes", @"renewable", nil];
	for(NSString *name in keys) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:[OAToken settingsKey:name provider:provider prefix:prefix]];
	}
}
			
+ (NSNumber *)durationWithString:(NSString *)aDuration {
	NSUInteger length = [aDuration length];
	unichar c = toupper([aDuration characterAtIndex:length - 1]);
	int mult;
	if (c >= '0' && c <= '9') {
		return [NSNumber numberWithInt:[aDuration intValue]];
	}
	if (c == 'S') {
		mult = 1;
	} else if (c == 'H') {
		mult = 60 * 60;
	} else if (c == 'D') {
		mult = 60 * 60 * 24;
	} else if (c == 'W') {
		mult = 60 * 60 * 24 * 7;
	} else if (c == 'M') {
		mult = 60 * 60 * 24 * 30;
	} else if (c == 'Y') {
		mult = 60 * 60 * 365;
	} else {
		mult = 1;
	}
	
	return [NSNumber numberWithInt: mult * [[aDuration substringToIndex:length - 1] intValue]];
}

+ (NSDictionary *)attributesWithString:(NSString *)theAttributes {
	NSArray *attrs = [theAttributes componentsSeparatedByString:@";"];
	NSMutableDictionary *dct = [[NSMutableDictionary alloc] init];
	for (NSString *pair in attrs) {
		NSArray *elements = [pair componentsSeparatedByString:@":"];
		[dct setObject:[elements objectAtIndex:1] forKey:[elements objectAtIndex:0]];
	}
	return [dct autorelease];
}

#pragma mark description

- (NSString *)description {
	return [NSString stringWithFormat:@"Key \"%@\" Secret:\"%@\"", key, secret];
}

@end
