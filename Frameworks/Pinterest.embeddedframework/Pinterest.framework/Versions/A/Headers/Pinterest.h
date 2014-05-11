//
//  Pinterest.h
//  Pinterest
//
//  Created by Naveen Gavini on 2/15/13.
//  Copyright (c) 2013 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/** The Pin It SDK allows for the creation of Pinterest content inside of third party applications.
 Currently the SDK only supports pinning images from a specified URL.
 */
@interface Pinterest : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialization
 *  ---------------------------------------------------------------------------------------
 */

/** Initializes a Pinterest instance.

 @warning An undefined clientId will raise a NSInvalidArgumentException on creating a pin.

 @param clientId A Pinterest client id.
 @return Pinterest instance.
 */
- (id)initWithClientId:(NSString *)clientId;

/** Initializes a Pinterest instance with a URL scheme suffix.
 
 @warning An undefined clientId will raise a NSInvalidArgumentException on creating a pin.

 @param clientId A Pinterest client id.
 @param suffix URL scheme suffix that is used to futher identify an application in addition to a client id.
 @return Pinterest instance.
 */
- (id)initWithClientId:(NSString *)clientId
       urlSchemeSuffix:(NSString *)suffix;


/**---------------------------------------------------------------------------------------
 * @name Pinning
 *  ---------------------------------------------------------------------------------------
 */

/** Checks if a version of the Pinterest app that supports the Pin It SDK is installed.

 @return If pinning is possible via the Pin It SDK on the device.
 */
- (BOOL)canPinWithSDK;


/** Creates a pin with specified image URL.

 @warning An undefined imageURL will raise a NSInvalidArgumentException.
 
 @param imageURL URL of the image to pin.
 @param sourceURL The source page of the image.
 @param descriptionText The pin's description.
 */
- (void)createPinWithImageURL:(NSURL *)imageURL
                    sourceURL:(NSURL *)sourceURL
                  description:(NSString *)descriptionText;

/** Creates a Pin It button.
 
 @return Pin It button.
 */
+ (UIButton *)pinItButton;

/**---------------------------------------------------------------------------------------
 * @name Deep Linking
 *  ---------------------------------------------------------------------------------------
 */

/** Opens the Pinterest application to a user's profile.

 @param username Username of user's profile to open.
 */
- (void)openUserWithUsername:(NSString *)username;

/** Opens the Pinterest application to a pin.

 @param identifier Id of the pin to open.
 */
- (void)openPinWithIdentifier:(NSString *)identifier;

/** Opens the Pinterest application to a user's board.

 The board's slug can be found from a board's URL on the web.

 @param slug The board's slug from a Pinterest URL.
 @param username The username of the user who owns the board.
 */
- (void)openBoardWithSlug:(NSString *)slug fromUser:(NSString *)username;

@end
