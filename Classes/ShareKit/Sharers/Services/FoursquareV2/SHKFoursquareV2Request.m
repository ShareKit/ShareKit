//
//  SHKFoursquareV2Request.m
//  TwoppyUI
//
//  Created by Robin Hos on 9/26/11.
//  Copyright 2011 Everdune. All rights reserved.
//

#import "SHKFoursquareV2Request.h"

#import "JSON.h"


static NSString *apiURL = @"https://api.foursquare.com/v2/";


@implementation SHKFoursquareV2Request

- (id)getJsonResult
{
    SBJSON *jsonParser = [[[SBJSON alloc] init] autorelease];
    
    return [jsonParser objectWithString:self.result];
}

- (NSArray*)getJsonArray
{
    id jsonResult = self.jsonResult;
    
    return [jsonResult isKindOfClass:[NSArray class]] ? jsonResult : nil;
}

- (NSDictionary*)getJsonObject
{
    id jsonResult = self.jsonResult;
    
    return [jsonResult isKindOfClass:[NSDictionary class]] ? jsonResult : nil;
}

+ (id)requestProfileForUserId:(NSString*)u delegate:(id)d isFinishedSelector:(SEL)s accessToken:(NSString*)t autostart:(BOOL)autostart
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@?oauth_token=%@", apiURL, u, t]];
    
    return [[[SHKFoursquareV2Request alloc] initWithURL:url 
                                                 params:nil 
                                               delegate:d 
                                     isFinishedSelector:s 
                                                 method:@"GET" 
                                              autostart:autostart] autorelease];
}


@end
