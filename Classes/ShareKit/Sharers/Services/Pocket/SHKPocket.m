//
//  SHKPocket.m
//  ShareKit
//
//  Created by Vilém Kurz on 5/11/13.
//
//

#import "SHKPocket.h"
#import "PocketAPI.h"
#import "SharersCommonHeaders.h"

@interface SHKPocket ()

@end

@implementation SHKPocket

#pragma mark -
#pragma mark Configuration : Service Defination

- (id)init {
    
    self = [super init];
    if (self) {
        [[PocketAPI sharedAPI] setConsumerKey:SHKCONFIG(pocketConsumerKey)];
    }
    return self;
}

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Pocket");
}

 + (BOOL)canShareURL
 {
     return YES;
 }

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized {
    
    return [[PocketAPI sharedAPI] isLoggedIn];
}

- (void)promptAuthorization {
    
    [self saveItemForLater:SHKPendingShare];
    
    [[PocketAPI sharedAPI] loginWithHandler: ^(PocketAPI *API, NSError *error){
        if (error != nil)
        {
            // There was an error when authorizing the user. The most common error is that the user denied access to your application.
            // The error object will contain a human readable error message that you should display to the user
            // Ex: Show an UIAlertView with the message from error.localizedDescription
            SHKLog(@"Pocket authorization error: %@", error.localizedDescription);
            
            [self authShowBadCredentialsAlert];
            [self authShowOtherAuthorizationErrorAlert];
            [self authDidFinish:NO];
        }
        else
        {
            // The user logged in successfully, your app can now make requests.
            // [API username] will return the logged-in user’s username and API.loggedIn will == YES
            [self authDidFinish:YES];
            [self restoreItem];
            [self tryPendingAction];
        }
    }];
}

+ (void)logout {
    
    [SHKPocket clearSavedItem];
    [[PocketAPI sharedAPI] logout];
}

#pragma mark -
#pragma mark Share Form

// If you have a share form the user will have the option to skip it in the future.
// If your form has required information and should never be skipped, uncomment this section.

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	if (type == SHKShareTypeURL)
		return [NSArray arrayWithObjects:
				[SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title],
				[SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag") key:@"tags" type:SHKFormFieldTypeText start:[self.item.tags componentsJoinedByString:@", "]],
				nil];
    
	return nil;
}


#pragma mark -
#pragma mark Implementation

// Send the share item to the server
- (BOOL)send
{
	// Make sure that the item has minimum requirements
	if (![self validateItem])
		return NO;
    
    [self sendDidStart];
    
    NSString *tags = [self tagStringJoinedBy:@"," allowedCharacters:nil tagPrefix:nil tagSuffix:nil];
    
    NSString *apiMethod = @"add";
    PocketAPIHTTPMethod httpMethod = PocketAPIHTTPMethodPOST; // usually PocketAPIHTTPMethodPOST
    NSDictionary *arguments = @{@"url": [self.item.URL absoluteString],
                                @"title": self.item.title,
                                @"tags": tags};
    
    [[PocketAPI sharedAPI] callAPIMethod:apiMethod
                          withHTTPMethod:httpMethod
                               arguments:arguments
                                 handler: ^(PocketAPI *api, NSString *apiMethod, NSDictionary *response, NSError *error){
                                     
                                     if (error) {
                                         
                                         [self sendShowSimpleErrorAlert];
                                         SHKLog(@"pocket send failed with error: %@", error.localizedDescription);
                                         
                                     } else {
                                         
                                         [self sendDidFinish];
                                     }
                                 }];
    return YES;
}

@end
