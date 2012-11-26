//
//  SHKiOSSharer_Protected.h
//  ShareKit
//
//  Created by Vilem Kurz on 18/11/2012.
//
//

#import "SHKiOSSharer.h"
#import <Social/Social.h>

@interface SHKiOSSharer ()

- (void)shareWithServiceType:(NSString *)serviceType;

/* services, which impose limit on text length should override this method and return its limit. Default is NSNotFound */
- (NSUInteger)maxTextLength;

/* returns nil by default. Subclasses which can pass tags directly in system dialogue might want to return properly concatenated tags ready to ship to service. */
- (NSString *)joinedTags;

@end
