//
//  SHKFoursquareV2Request.h
//  TwoppyUI
//
//  Created by Robin Hos on 9/26/11.
//  Copyright 2011 Everdune. All rights reserved.
//

#import "SHKRequest.h"

@interface SHKFoursquareV2Request : SHKRequest

@property (nonatomic, readonly, getter=getJsonResult) id jsonResult;
@property (nonatomic, readonly, getter=getJsonArray) NSArray *jsonArray;
@property (nonatomic, readonly, getter=getJsonObject) NSDictionary *jsonObject;

+ (id)requestProfileForUserId:(NSString*)u delegate:(id)d isFinishedSelector:(SEL)s accessToken:(NSString*)t autostart:(BOOL)autostart;

@end
