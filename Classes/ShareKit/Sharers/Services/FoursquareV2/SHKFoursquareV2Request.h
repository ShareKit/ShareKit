//
//  SHKFoursquareV2Request.h
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

#import <CoreLocation/CoreLocation.h>

#import "SHKRequest.h"

#import "SHKFoursquareV2Venue.h"
#import "NSError+SHKFoursquareV2.h"

@interface SHKFoursquareV2Request : SHKRequest

@property (nonatomic, strong, readonly) NSDictionary *foursquareResponse;
@property (nonatomic, strong, readonly) NSError *foursquareError;

+ (void)startRequestProfileForUserId:(NSString*)u accessToken:(NSString*)t completion:(RequestCallback)completion;
+ (void)startRequestVenuesSearchLocation:(CLLocation*)l query:(NSString*)q accessToken:(NSString*)t completion:(RequestCallback)completion;
+ (void)startRequestCheckinLocation:(CLLocation*)l venue:(SHKFoursquareV2Venue*)v message:(NSString*)m accessToken:(NSString*)t completion:(RequestCallback)completion;

@end
