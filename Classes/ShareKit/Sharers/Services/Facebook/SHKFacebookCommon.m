//
//  SHKFacebookCommon.m
//  ShareKit
//
//  Created by Vilém Kurz on 11/11/13.
//
//

#import "SHKFacebookCommon.h"

#import "SharersCommonHeaders.h"

NSString *const kSHKFacebookUserInfo = @"kSHKFacebookUserInfo";
NSString *const kSHKFacebookVideoUploadLimits = @"kSHKFacebookVideoUploadLimits";
NSString *const kSHKFacebookAPIUserInfoURL = @"https://graph.facebook.com/v2.2/me";
NSString *const kSHKFacebookAPIFeedURL = @"https://graph.facebook.com/v2.2/me/feed";
NSString *const kSHKFacebookAPIPhotosURL = @"https://graph.facebook.com/v2.2/me/photos";
NSString *const kSHKFacebookAPIVideosURL = @"https://graph.facebook.com/v2.2/me/videos";

#define ACTIONS_API_KEY @"actions"
#define LINK_API_KEY @"link"
#define NAME_API_KEY @"name"
#define MESSAGE_API_KEY @"message"
#define PICTURE_API_KEY @"picture"
#define DESCRIPTION_API_KEY @"description"
#define TITLE_API_KEY @"title"

#define USERNAME_INFO_KEY @"name"

@implementation SHKFacebookCommon

+ (BOOL)canFacebookAcceptFile:(SHKFile *)file {
    
    NSArray *facebookValidTypes = @[@"3g2",@"3gp" ,@"3gpp" ,@"asf",@"avi",@"dat",@"flv",@"m4v",@"mkv",@"mod",@"mov",@"mp4",
                        @"mpe",@"mpeg",@"mpeg4",@"mpg",@"nsv",@"ogm",@"ogv",@"qt" ,@"tod",@"vob",@"wmv"];
    
    for (NSString *extension in facebookValidTypes) {
        
        if ([file.filename hasSuffix:extension]) {
            
            NSDictionary *limits = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKFacebookVideoUploadLimits];
            
            //video limits are not downloaded. This can happen if user is not yet authenticated. We should not slow action sheet, so instead of waiting for userInfo fetch we rather return YES.
            if (!limits) return YES;
            
            NSUInteger maxVideoSize = [limits[@"video_upload_limits"][@"size"] unsignedIntegerValue];
            BOOL isUnderSize = maxVideoSize >= file.size;
            NSUInteger maxVideoDuration = (int)limits[@"video_upload_limits"][@"length"];
            BOOL isUnderDuration = maxVideoDuration >= file.duration;
            
            BOOL result = isUnderDuration && isUnderSize;
            return result;
        }
    }
    
    return NO;
}

+ (BOOL)socialFrameworkAvailable {
    
    if (NSClassFromString(@"SLComposeViewController") && ![SHKCONFIG(forcePreIOS6FacebookPosting) boolValue]) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKFacebookUserInfo];
    NSString *result = userInfo[USERNAME_INFO_KEY];
    return result;
}

+ (NSMutableDictionary *)composeParamsForItem:(SHKItem *)item {
    
    NSMutableDictionary *result = [@{} mutableCopy];
    
    NSString *actions = [NSString stringWithFormat:@"{\"name\":\"%@ %@\",\"link\":\"%@\"}",
                         SHKLocalizedString(@"Get"), SHKCONFIG(appName), SHKCONFIG(appURL)];
    [result setObject:actions forKey:ACTIONS_API_KEY];
    
    switch (item.shareType) {
        case SHKShareTypeText:
        case SHKShareTypeURL:
        {
            if (item.URL) {
                NSString *url = [item.URL absoluteString];
                [result setObject:url forKey:LINK_API_KEY];
            }
            
            if (item.title) [result setObject:item.title forKey:NAME_API_KEY];
            if (item.text) [result setObject:item.text forKey:MESSAGE_API_KEY];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            NSString *pictureURI = item.URLPictureURI ? [item.URLPictureURI absoluteString] : item.facebookURLSharePictureURI;
            if (pictureURI) [result setObject:pictureURI forKey:PICTURE_API_KEY];

            NSString *description = item.URLDescription ? item.URLDescription : item.facebookURLShareDescription;
#pragma clang diagnostic pop
            if (description) [result setObject:description forKey:DESCRIPTION_API_KEY];
            break;
        }
        case SHKShareTypeImage:
            if (item.title) [result setObject:item.title forKey:MESSAGE_API_KEY];
            break;
        case SHKShareTypeFile:
            if (item.title) [result setObject:item.title forKey:TITLE_API_KEY];
            if (item.text) [result setObject:item.text forKey:DESCRIPTION_API_KEY];
            break;
        default:
            break;
    }
    return result;
}

+ (NSMutableArray *)shareFormFieldsForItem:(SHKItem *)item {
    
    if (item.shareType == SHKShareTypeUserInfo) return nil;
    
    NSString *text;
    NSString *key;
    BOOL allowEmptyMessage = NO;
    
    switch (item.shareType) {
        case SHKShareTypeText:
            text = item.text;
            key = @"text";
            break;
        case SHKShareTypeImage:
            text = item.title;
            key = @"title";
            allowEmptyMessage = YES;
            break;
        case SHKShareTypeURL:
            text = item.text;
            key = @"text";
            allowEmptyMessage = YES;
            break;
        case SHKShareTypeFile:
            text = item.text;
            key = @"text";
            break;
        default:
            return nil;
    }
    
    SHKFormFieldLargeTextSettings *commentField = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Comment")
                                                                                   key:key
                                                                                 start:text
                                                                                  item:item];
    commentField.select = YES;
    commentField.validationBlock = ^ (SHKFormFieldLargeTextSettings *formFieldSettings) {
        
        BOOL result;
        
        if (allowEmptyMessage) {
            result = YES;
        } else {
            result = [formFieldSettings.valueToSave length] > 0;
        }
        
        return result;
    };
    
    NSMutableArray *result = [@[commentField] mutableCopy];
    
    if (item.shareType == SHKShareTypeURL || item.shareType == SHKShareTypeFile) {
        SHKFormFieldSettings *title = [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:item.title];
        [result insertObject:title atIndex:0];
    }
    return result;
}

@end
