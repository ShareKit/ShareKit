//
//  SHKTwitterConstants.m
//  ShareKit
//
//  Created by Vilém Kurz on 05/11/13.
//
//

#import "SHKTwitterCommon.h"

#import "NSMutableDictionary+NSNullsToEmptyStrings.h"
#import "SharersCommonHeaders.h"
#import "SHKXMLResponseParser.h"
#import "SHKSharer.h"

NSString * const kSHKTwitterUserInfo=@"kSHKTwitterUserInfo";
NSString * const kSHKiOSTwitterUserInfo = @"kSHKiOSTwitterUserInfo";
NSString * const SHKTwitterAPIConfigurationDataKey = @"SHKTwitterAPIConfigurationDataKey";
NSString * const SHKTwitterAPIConfigurationSaveDateKey = @"SHKTwitterAPIConfigurationSaveDateKey";

NSString * const SHKTwitterAPIUserInfoURL = @"https://api.twitter.com/1.1/account/verify_credentials.json";
NSString * const SHKTwitterAPIUserInfoNameKey = @"screen_name";

NSString * const SHKTwitterAPIConfigurationURL = @"https://api.twitter.com/1.1/help/configuration.json";
NSString * const SHKTwitterAPIUpdateWithMediaURL = @"https://api.twitter.com/1.1/statuses/update_with_media.json";
NSString * const SHKTwitterAPIUpdateURL = @"https://api.twitter.com/1.1/statuses/update.json";

#define MAX_TWEET_LENGTH 140
#define MAX_FILE_SIZE 3145728
#define API_CONFIG_PHOTO_SIZE_KEY @"photo_size_limit"
#define CHARS_PER_MEDIA 23
#define API_CONFIG_CHARACTERS_RESERVED_PER_MEDIA @"characters_reserved_per_media"
#define CHARS_PER_URL 23
#define API_CONFIG_CHARACTERS_RESERVED_PER_URL @"short_url_length_https"

#define REVOKED_ACCESS_ERROR_CODE 32
#define INVALID_TOKEN_ERROR_CODE 89

@implementation SHKTwitterCommon

+ (BOOL)canShareFile:(SHKFile *)file {
    
    BOOL isVideo = [file.mimeType hasPrefix:@"video/"]; //all videos are supported by Yfrog
    BOOL isSupportedImage = [file.mimeType isEqualToString:@"image/png"] || [file.mimeType isEqualToString:@"image/gif"] || [file.mimeType isEqualToString:@"image/jpeg"] || [file.mimeType isEqualToString:@"image/bmp"] || [file.mimeType isEqualToString:@"image/x-windows-bmp"];
    
    if (isVideo || isSupportedImage) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)prepareItem:(SHKItem *)item joinedTags:(NSString *)hashtags {
    
    NSString *status = item.shareType == SHKShareTypeText ? item.text : item.title;
    
    if ([hashtags length] > 0)
    {
        status = [NSString stringWithFormat:@"%@ %@", status, hashtags];
    }
    
    if (item.URL)
    {
        NSString *URLstring = [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        status = [NSString stringWithFormat:@"%@ %@", status, URLstring];
    }
    [item setCustomValue:status forKey:@"status"];
}


+ (BOOL)socialFrameworkAvailable {
    
    if ([SHKCONFIG(forcePreIOS5TwitterAccess) boolValue])
    {
        return NO;
    }
    
	if (NSClassFromString(@"SLComposeViewController"))
    {
		return YES;
	}
	
	return NO;
}

#pragma mark - Fetch Twitter API configuration

+ (NSUInteger)maxTwitterFileSize {
    
    NSDictionary *twitterAPIConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHKTwitterAPIConfigurationDataKey];
    NSUInteger result = [twitterAPIConfig[API_CONFIG_PHOTO_SIZE_KEY] integerValue];
    if (!result) {
        result = MAX_FILE_SIZE;//if not fetched yet, return last known value. This must be quick in order not to slow share menu creation.
    }
    return result;
}

+ (NSUInteger)charsReservedPerMedia {
    
    NSDictionary *twitterAPIConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHKTwitterAPIConfigurationDataKey];
    NSUInteger result = [twitterAPIConfig[API_CONFIG_CHARACTERS_RESERVED_PER_MEDIA] integerValue];
    if (!result) {
        result = CHARS_PER_MEDIA;//if not fetched yet, return last known value.
    }
    return result;
}

+ (NSUInteger)charsReservedPerURL {
    
    NSDictionary *twitterAPIConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SHKTwitterAPIConfigurationDataKey];
    NSUInteger result = [twitterAPIConfig[API_CONFIG_CHARACTERS_RESERVED_PER_URL] integerValue];
    if (!result) {
        result = CHARS_PER_URL;//if not fetched yet, return last known value.
    }
    return result;
}

+ (BOOL)canTwitterAcceptFile:(SHKFile *)file {
    
    BOOL isSupportedImage = [file.mimeType isEqualToString:@"image/png"] || [file.mimeType isEqualToString:@"image/gif"] || [file.mimeType isEqualToString:@"image/jpeg"];
    BOOL isSizeSupported = file.size < [self maxTwitterFileSize];
    BOOL result = isSupportedImage && isSizeSupported;
    return result;
}

#pragma mark - UI Configuration

+ (NSUInteger)maxTextLengthForItem:(SHKItem *)item {
    
    //if media is attached there is less room for user's tweet text
    NSUInteger textLengthToSubtract = 0;
    if (item.file) {
        textLengthToSubtract += [SHKTwitterCommon charsReservedPerMedia];
    } else if (item.image) {
        textLengthToSubtract += [SHKTwitterCommon charsReservedPerURL]; //the image link is shortened natively by Twitter anyway via t.co)
    }
    
    //if url is attached there is less room for user's tweet text
    if (item.URL) {
        textLengthToSubtract += [SHKTwitterCommon charsReservedPerURL];
    }
    
    //link is shortened natively by Twitter via t.co, and the original link itself does not eat up to 140 chars limit, thus we add url length
    NSUInteger result = MAX_TWEET_LENGTH + [[item.URL absoluteString] length] - textLengthToSubtract;
    return result;
}

#pragma mark - response data handling

+ (void)saveData:(NSData *)data defaultsKey:(NSString *)key {
    
    NSError *error = nil;
    NSMutableDictionary *parsedData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        SHKLog(@"Error when parsing json %@ request:%@", key, [error description]);
    }
    
    [parsedData convertNSNullsToEmptyStrings];
    
    if ([key isEqualToString:kSHKiOSTwitterUserInfo]) {
        
        //there can be multiple accounts authorized (e.g. SHKiOSTwitter)
        NSArray *existingAuthorizedAccounts = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (existingAuthorizedAccounts) {
            NSMutableArray *existingAccountsMutable = [existingAuthorizedAccounts mutableCopy];
            [existingAccountsMutable addObject:parsedData];
            existingAuthorizedAccounts = existingAccountsMutable;
        } else {
            existingAuthorizedAccounts = @[parsedData];
        }
        SHKLog(@"fetched user info data: %@", [existingAuthorizedAccounts description]);
        [[NSUserDefaults standardUserDefaults] setObject:existingAuthorizedAccounts forKey:key];
        
    } else {
        
        SHKLog(@"fetched user api config: %@", [parsedData description]);
        [[NSUserDefaults standardUserDefaults] setObject:parsedData forKey:key];
    }
}

+ (void)handleUnsuccessfulTicket:(NSData *)data forSharer:(SHKSharer *)sharer {
    
	if (SHKDebugShowLogs)
		SHKLog(@"Twitter Send Status Error: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	
	NSMutableDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSDictionary *twitterError = parsedResponse[@"errors"][0];
	
	if ([twitterError[@"code"] integerValue] == REVOKED_ACCESS_ERROR_CODE || [twitterError[@"code"] integerValue] == INVALID_TOKEN_ERROR_CODE) {
		
		[sharer shouldReloginWithPendingAction:SHKPendingSend];
        return;
		
	} else {
		
		//when sharing image, and the user removed app permissions there is no JSON response expected above, but XML, which we need to parse. 401 is obsolete credentials -> need to relogin
		if ([[SHKXMLResponseParser getValueForElement:@"code" fromXMLData:data] isEqualToString:@"401"]) {
			
			[sharer shouldReloginWithPendingAction:SHKPendingSend];
			return;
		}
	}
	
	NSError *error = [NSError errorWithDomain:@"Twitter" code:2 userInfo:[NSDictionary dictionaryWithObject:twitterError[@"message"] forKey:NSLocalizedDescriptionKey]];
	[sharer sendDidFailWithError:error];
}

@end
