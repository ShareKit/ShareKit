//
//  SHKOAuthViewDelegate.h
//  ShareKit
//
//  Created by Vilem Kurz on 11/04/2014.
//
//

#import <Foundation/Foundation.h>

@class SHKOAuthView;

@protocol SHKOAuthViewDelegate <NSObject>

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error;
- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView;
- (NSURL *)authorizeCallbackURL;

@end