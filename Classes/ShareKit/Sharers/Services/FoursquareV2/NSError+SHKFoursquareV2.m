//
//  NSError+SHKFoursquareV2.m
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

#import "SHK.h"
#import "NSError+SHKFoursquareV2.h"

NSString *SHKFoursquareV2ErrorDomain = @"SHKFoursquareV2ErrorDomain";
NSString *SHKFoursquareV2ErrorTypeKey = @"SHKFoursquareV2ErrorTypeKey";
NSString *SHKFoursquareV2MetaKey = @"SHKFoursquareV2MetaKey";


@implementation NSError (SHKFoursquareV2)

- (BOOL)getFoursquareRelogin
{
    return [self.domain isEqualToString:SHKFoursquareV2ErrorDomain] && self.code == 401;
}

+ (NSError*)errorWithFoursquareMeta:(NSDictionary*)meta
{
    NSNumber *code = [meta objectForKey:@"code"];
    
    NSString *errorType = [meta objectForKey:@"errorType"];
    
    NSString *localizedDescription;
    
    switch (code.integerValue) {
        case 401:
            localizedDescription = SHKLocalizedString(@"Could not authenticate you. Please relogin.");
            break;
            
        default:
            localizedDescription = SHKLocalizedString(@"There was an error while sharing");
            break;
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: 
                              errorType, SHKFoursquareV2ErrorTypeKey,
                              meta, SHKFoursquareV2MetaKey,
                              localizedDescription, NSLocalizedDescriptionKey,
                              nil];
    
    return [NSError errorWithDomain:SHKFoursquareV2ErrorDomain code:code.integerValue userInfo:userInfo];
}

@end
