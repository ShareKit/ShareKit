//
//  SHKFacebookCommon.h
//  ShareKit
//
//  Created by Vilém Kurz on 11/11/13.
//
//

/*!
 The purpose of this class is to serve common code for SHKFacebook and SHKiOSFacebook in order to avoid code duplication */

#import <Foundation/Foundation.h>

@class SHKFile;
@class SHKItem;

extern NSString *const kSHKFacebookUserInfo;
extern NSString *const kSHKFacebookVideoUploadLimits;
extern NSString *const kSHKFacebookAPIUserInfoURL;
extern NSString *const kSHKFacebookAPIFeedURL;
extern NSString *const kSHKFacebookAPIPhotosURL;
extern NSString *const kSHKFacebookAPIVideosURL;

@interface SHKFacebookCommon : NSObject

+ (BOOL)canFacebookAcceptFile:(SHKFile *)file;
+ (BOOL)socialFrameworkAvailable;
+ (NSString *)username;
+ (NSMutableDictionary *)composeParamsForItem:(SHKItem *)item;
+ (NSMutableArray *)shareFormFieldsForItem:(SHKItem *)item;

@end
