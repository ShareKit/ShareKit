//
//  SHKTwitterConstants.h
//  ShareKit
//
//  Created by Vilém Kurz on 05/11/13.
//
//

@class SHKFile;
@class SHKItem;

#import <Foundation/Foundation.h>

extern NSString * const kSHKTwitterUserInfo;
extern NSString * const kSHKiOSTwitterUserInfo;
extern NSString * const SHKTwitterAPIConfigurationDataKey;
extern NSString * const SHKTwitterAPIConfigurationSaveDateKey;
extern NSString * const SHKTwitterAPIUserInfoURL;
extern NSString * const SHKTwitterAPIUserInfoNameKey;
extern NSString * const SHKTwitterAPIConfigurationURL;
extern NSString * const SHKTwitterAPIUpdateWithMediaURL;
extern NSString * const SHKTwitterAPIUpdateURL;

@interface SHKTwitterCommon : NSObject

+ (void)saveData:(NSData *)data defaultsKey:(NSString *)key;
+ (void)prepareItem:(SHKItem *)item joinedTags:(NSString *)hashtags;

+ (BOOL)canTwitterAcceptFile:(SHKFile *)file;
+ (BOOL)canTwitterAcceptImage:(UIImage *)image convertedData:(NSData **)data;
+ (BOOL)socialFrameworkAvailable;

#pragma mark - Fetch Twitter API Configuration

+ (NSUInteger)maxTwitterFileSize;
+ (NSUInteger)charsReservedPerMedia;
+ (NSUInteger)charsReservedPerURL;

#pragma mark - UI Configuration

+ (NSUInteger)maxTextLengthForItem:(SHKItem *)item;

@end
