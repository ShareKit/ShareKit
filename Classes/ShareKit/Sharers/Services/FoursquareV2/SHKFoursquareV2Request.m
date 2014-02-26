//
//  SHKFoursquareV2Request.m
//  ShareKit
//
//  Created by Robin Hos (Everdune) on 9/26/11.
//  Sponsored by Twoppy
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
//
//

#import "SHKFoursquareV2Request.h"
#import "NSString+URLEncoding.h"

static NSString *apiURL = @"https://api.foursquare.com/v2";
static NSString *apiDateVerified = @"20140128";

@interface SHKFoursquareV2Request ()

@property (nonatomic, strong) NSDictionary *foursquareResult;
@property (nonatomic, strong) NSDictionary *foursquareMeta;
@property (nonatomic, strong) NSDictionary *foursquareResponse;
@property (nonatomic, strong) NSError *foursquareError;

@end

@implementation SHKFoursquareV2Request


- (NSDictionary*)foursquareResult
{
    if (_foursquareResult == nil) {
        
        NSError *error = nil;
        id jsonResult = [NSJSONSerialization JSONObjectWithData:self.data options:NSJSONReadingMutableContainers error:&error];
        
        _foursquareResult = ([jsonResult isKindOfClass:[NSDictionary class]] ? jsonResult : nil);
    }
    
    return _foursquareResult;
}

- (NSDictionary*)foursquareMeta
{
    return [self.foursquareResult objectForKey:@"meta"];
}

- (NSDictionary*)foursquareResponse
{
    return [self.foursquareResult objectForKey:@"response"];
}

- (NSError*)foursquareError
{
    if (self.success) {
        return nil;
    }
    
    if (_foursquareError == nil) {
        _foursquareError = [NSError errorWithFoursquareMeta:self.foursquareMeta];
    }
    
    return _foursquareError;
}

- (void) start
{
    _foursquareResult = nil;
    _foursquareError = nil;
    
    [super start];
}

+ (void)startRequestProfileForUserId:(NSString*)u accessToken:(NSString*)t completion:(RequestCallback)completion
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/users/%@?oauth_token=%@&v=%@", apiURL, u, t, apiDateVerified]];
    
    [SHKFoursquareV2Request startWithURL:url params:nil method:@"GET" completion:completion];
}

+ (void)startRequestVenuesSearchLocation:(CLLocation*)l query:(NSString*)q accessToken:(NSString*)t completion:(RequestCallback)completion {
    
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/venues/search?oauth_token=%@&v=%@", apiURL, t, apiDateVerified];
    [url appendFormat:@"&ll=%.5lf,%.5lf", l.coordinate.latitude, l.coordinate.longitude];
    [url appendFormat:@"&llAcc=%.2lf", l.horizontalAccuracy];
    [url appendFormat:@"&alt=%.2lf", l.altitude];
    [url appendFormat:@"&altAcc=%.2lf", l.verticalAccuracy];
    if (q != nil)
    {
        [url appendFormat:@"&query=%@", [q URLEncodedString]];
    }

    [SHKFoursquareV2Request startWithURL:[NSURL URLWithString:url] params:nil method:@"GET" completion:completion];    
}

+ (void)startRequestCheckinLocation:(CLLocation*)l venue:(SHKFoursquareV2Venue*)v message:(NSString*)m accessToken:(NSString*)t completion:(RequestCallback)completion;
{
    NSMutableString *url = [NSMutableString stringWithFormat:@"%@/checkins/add?oauth_token=%@&v=%@", apiURL, t, apiDateVerified];
    [url appendFormat:@"&venueId=%@", v.venueId];
    [url appendFormat:@"&ll=%.5lf,%.5lf", l.coordinate.latitude, l.coordinate.longitude];
    [url appendFormat:@"&llAcc=%.2lf", l.horizontalAccuracy];
    [url appendFormat:@"&alt=%.2lf", l.altitude];
    [url appendFormat:@"&altAcc=%.2lf", l.verticalAccuracy];
    
    if (m != nil && m.length > 0) {
        [url appendFormat:@"&shout=%@", [m URLEncodedString]];
    }
    
    [SHKFoursquareV2Request startWithURL:[NSURL URLWithString:url]
                                  params:@"" // Otherwise, the method won't be set in SHKRequest start
                                  method:@"POST"
                              completion:completion];
}

@end