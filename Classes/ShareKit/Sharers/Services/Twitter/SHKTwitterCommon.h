//
//  SHKTwitterConstants.h
//  ShareKit
//
//  Created by Vilém Kurz on 05/11/13.
//
//

@class SHKFile;
@class SHKItem;
@class SHKSharer;

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

+ (void)prepareItem:(SHKItem *)item joinedTags:(NSString *)hashtags;

+ (BOOL)canShareFile:(SHKFile *)file;
+ (BOOL)canTwitterAcceptFile:(SHKFile *)file;
+ (BOOL)socialFrameworkAvailable;

#pragma mark - Fetch Twitter API Configuration

+ (NSUInteger)maxTwitterFileSize;
+ (NSUInteger)charsReservedPerMedia;
+ (NSUInteger)charsReservedPerURL;

#pragma mark - UI Configuration

+ (NSUInteger)maxTextLengthForItem:(SHKItem *)item;

#pragma mark - response data handling

+ (void)saveData:(NSData *)data defaultsKey:(NSString *)key;
+ (void)handleUnsuccessfulTicket:(NSData *)data forSharer:(SHKSharer *)sharer;

@end
