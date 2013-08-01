//
//  UIImage+OurBundle.m
//  ShareKit
//
//  Created by Vilem Kurz on 01/08/2013.
//
//

#import "UIImage+OurBundle.h"
#import "SHKConfiguration.h"

@implementation UIImage (OurBundle)

+ (UIImage *)imageNamedFromOurBundle:(NSString *)name {
    
    BOOL usesPods = [SHKCONFIG(isUsingCocoaPods) boolValue];
    UIImage *result;
    
    if (usesPods) {
        result = [UIImage imageNamed:name];
    } else {
        NSString *ourBundlePath = [@"ShareKit.bundle" stringByAppendingPathComponent:name];
        result = [UIImage imageNamed:ourBundlePath];
    }
    
    return result;
}

@end
