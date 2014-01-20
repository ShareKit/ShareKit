//
//  SHKFoursquareV2Venue.m
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

#import "SHKFoursquareV2Venue.h"

@implementation SHKFoursquareV2Venue

+ (id)venueFromDictionary:(NSDictionary*)dictionary
{
    SHKFoursquareV2Venue *venue = [[self alloc] init];
    
    venue.venueId = [dictionary objectForKey:@"id"];
    venue.name = [dictionary objectForKey:@"name"];
    
    NSDictionary *location = [dictionary objectForKey:@"location"];
    venue.address = [location objectForKey:@"address"];
    
    // Find primary category and get the icon
    NSArray *categories = [dictionary objectForKey:@"categories"];
    for (NSUInteger i = 0; i < [categories count]; ++i) 
    {
        NSDictionary *category = [categories objectAtIndex:i];
        NSNumber *primary = [category objectForKey:@"primary"];
        if ([primary boolValue]) {
            venue.icon = [category objectForKey:@"icon"];
            break;
        }
    }
    
    return venue;
}


@end
