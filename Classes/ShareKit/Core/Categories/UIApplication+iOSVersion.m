//
//  UIApplication+iOSVersion.m
//  ShareKit
//
//  Created by Vilém Kurz on 10/15/13.
//
//

#import "UIApplication+iOSVersion.h"

#define SHKFoundationVersionNumber_iOS_6_1  993.00

@implementation UIApplication (iOSVersion)

- (BOOL)isiOS6OrOlder {
    
    if (floor(NSFoundationVersionNumber) <= SHKFoundationVersionNumber_iOS_6_1) {
        return YES;
    }   else {
        return NO;
    }
}

@end
