//
//  SHKGooglePlus.h
//  ShareKit
//
//  Created by CocoaBob on 12/31/12.
//
//

// To use SHKGooglePlus, please follow these steps:
//
// 1. Create a project on Google APIs console,
//    https://code.google.com/apis/console . Under "API Access", create a
//    client ID as "Installed application" with the type "iOS", and
//    register the bundle ID of your application.
//
// 2. In your customized ShareKitConfigurator, implement with the new created client ID
//    - (NSString*)googlePlusClientId {
//        return YOUR_CLIENT_ID;
//    }
//
// 3. In the 'YourApp-info.plist' settings for your application, add a URL
//    type to be handled by your application. Make the URL scheme the same as
//    the bundle ID of your application.
//
// 4. In your application delegate, #import "SHKGooglePlus.h" and implement
//    - (BOOL)application:(NSString*)application
//                openURL:(NSURL *)url
//      sourceApplication:(NSString*)sourceApplication
//             annotation:(id)annotation {
//      if ([[[SHKGooglePlus shared] mGooglePlusShare] handleURL:url sourceApplication:sourceApplication annotation:annotation]) {
//          return YES;
//      }
//      // Other handling code here...
//    }

#import "SHKSharer.h"
#import <GooglePlus/GooglePlus.h>


@interface SHKGooglePlus : SHKSharer <GPPShareDelegate, GPPSignInDelegate>

+ (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end