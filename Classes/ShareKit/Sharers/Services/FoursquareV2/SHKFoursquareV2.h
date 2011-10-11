//
//  SHKFoursquareV2.h
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
//  Notes: 
//
//  1) This sharer assumes SBJSON is present (this will automatically be the
//     case if the Facebook sharer is included 
//
//  2) The sharer needs the location services which are not available in the simulator
//     (it will show up on a real device)
//
//

#import "SHKSharer.h"

#import "SHKFoursquareV2Request.h"
#import "SHKFoursquareV2Venue.h"

@interface SHKFoursquareV2 : SHKSharer {
    NSString *_clientId;
    NSURL *_authorizeCallbackURL;
    
    NSString *_accessToken;
    
    CLLocation *_location;
    SHKFoursquareV2Venue *_venue;
}

@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSURL *authorizeCallbackURL;

@property (nonatomic, copy) NSString *accessToken;

@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, retain) SHKFoursquareV2Venue *venue;


- (void)showFoursquareV2VenuesForm;
- (void)showFoursquareV2CheckInForm;

- (void)startCheckInRequest;
- (void)finishCheckInRequest:(SHKFoursquareV2Request*)sender;

@end
