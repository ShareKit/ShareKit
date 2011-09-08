ShareKit 2.0
============

In order to make it easier for new users to choose a canonical fork of ShareKit, the ShareKit community has decided to band together and take responsibility for collecting useful commits into what we're calling "ShareKit 2.0". In the next week or two, we'll be working to test and release the first officially stable version of ShareKit since February, with more frequent updates expected thereafter.

You can follow the initial planning at https://github.com/ideashower/ShareKit/issues/283.

Many thanks to @ideashower for birthing ShareKit.

Installation
------------

1. Download and unpack the [latest stable release](https://github.com/clozach/ShareKit/archives/master).
2. Include SHKFacebook.h at the top of your AppDelegate.m:

        #import "SHKFacebook.h"

3. In your AppDelegate, include these two methods (or merge if you already use them, remembering to properly delegate):

        - (BOOL)application:(UIApplication *)application 
                    openURL:(NSURL *)url 
          sourceApplication:(NSString *)sourceApplication 
                 annotation:(id)annotation 
        {
            return [SHKFacebook handleOpenURL:url];
        }

        - (BOOL)application:(UIApplication *)application 
              handleOpenURL:(NSURL *)url 
        {
            return [SHKFacebook handleOpenURL:url];
        }

4. In your App-Info.plist, include this property...

        <key>CFBundleURLTypes</key>
        <array>
                <dict>
                        <key>CFBundleURLName</key>
                        <string></string>
                        <key>CFBundleURLSchemes</key>
                        <array>
                                <string>fb${FACEBOOK_APP_ID}</string>
                        </array>
                </dict>
        </array>

...where ```fb${FACEBOOK_APP_ID}``` looks like ```fb1234```

5. Finally, in SHKConfig.h, set the facebook API ID:

        #define SHKFacebookAppID @"1234"

Where to go next
----------------

With the caveat that <font color="red">the release on getsharekit.com is obsolete as of this writing</font>:

How to add new services:
http://getsharekit.com/add

How to customize the look of ShareKit:
http://getsharekit.com/customize

Full documentation:
http://getsharekit.com/docs