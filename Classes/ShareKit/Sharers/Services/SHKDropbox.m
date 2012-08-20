//
//  SHKDropbox.m
//  ShareKit
//
//  Created by Orifjon Meliboyev on 12/07/23.
//  Copyright (c) 2012 SSD. All rights reserved.
//

#import "SHKDropbox.h"
#import "SHKConfiguration.h"

@interface SHKDropbox () <DBRestClientDelegate>

@property(nonatomic, readonly) DBRestClient *restClient;
@end

@implementation SHKDropbox
@synthesize restClient;

#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return @"Dropbox";
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)canShareFile
{
    return YES;
}

+ (BOOL)requiresAuthentication
{
    return YES;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	return YES;
}



#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{	
    if (![DBSession sharedSession]) {
        return NO; //[self promptAuthorization];
    }
	return [[DBSession sharedSession] isLinked];
}


- (void)promptAuthorization{
    
    NSString *root = SHKCONFIG(dropboxRoot)?kDBRootDropbox:kDBRootAppFolder; // Should be set to either kDBRootAppFolder or kDBRootDropbox
    // You can determine if you have App folder access or Full Dropbox along with your consumer key/secret
    // from https://dropbox.com/developers/apps 
    
    NSString *consumerKey = SHKCONFIG(dropboxConsumerKey);
    NSString *secretKey = SHKCONFIG(dropboxSecretKey);
    NSString* errorMsg = nil;
    if ([consumerKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app key correctly";
    } else if ([secretKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app secret correctly";
    } else if ([root length] == 0) {
        errorMsg = @"Set your root to use either App Folder of full Dropbox";
    } 
    
    DBSession* session = 
    [[DBSession alloc] initWithAppKey:consumerKey appSecret:secretKey root:root];
    session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
    [DBSession setSharedSession:session];
    [session release];
    
    if (errorMsg != nil) {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error Configuring Session" message:errorMsg 
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
    }
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:[[SHK currentHelper] rootViewForCustomUIDisplay]];
    }
    [self retain];
}

- (void) authComplete 
{
	if (self.item) 
		[self share];
    [self release];
}

+ (void)logout
{
    [[DBSession sharedSession] unlinkAll];
}

// If you need to add additional headers or parameters to the request_token request, uncomment this section:
/*
 - (void)tokenRequestModifyRequest:(OAMutableURLRequest *)oRequest
 {
 // Here is an example that adds the user's callback to the request headers
 [oRequest setOAuthParameterName:@"oauth_callback" withValue:authorizeCallbackURL.absoluteString];
 }
 */

// If you need to add additional headers or parameters to the access_token request, uncomment this section:
/*
 - (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
 {
 // Here is an example that adds the oauth_verifier value received from the authorize call.
 // authorizeResponseQueryVars is a dictionary that contains the variables sent to the callback url
 [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
 }
 */


#pragma mark -
#pragma mark Share Form

// If your action has options or additional information it needs to get from the user,
// use this to create the form that is presented to user upon sharing.
/*
 - (NSArray *)shareFormFieldsForType:(SHKShareType)type
 {
 // See http://getsharekit.com/docs/#forms for documentation on creating forms
 
 if (type == SHKShareTypeURL)
 {
 // An example form that has a single text field to let the user edit the share item's title
 return [NSArray arrayWithObjects:
 [SHKFormFieldSettings label:@"Title" key:@"title" type:SHKFormFieldTypeText start:item.title],
 nil];
 }
 
 else if (type == SHKShareTypeImage)
 {
 // return a form if required when sharing an image
 return nil;		
 }
 
 else if (type == SHKShareTypeText)
 {
 // return a form if required when sharing text
 return nil;		
 }
 
 else if (type == SHKShareTypeFile)
 {
 // return a form if required when sharing a file
 return nil;		
 }
 
 return nil;
 }
 */

// If you have a share form the user will have the option to skip it in the future.
// If your form has required information and should never be skipped, uncomment this section.
/*
 + (BOOL)canAutoShare
 {
 return NO;
 }
 */

// Validate the user input on the share form
- (void)shareFormValidate:(SHKFormController *)form
{	
	/*
	 
	 Services should subclass this if they need to validate any data before sending.
	 You can get a dictionary of the field values from [form formValues]
	 
	 --
	 
	 You should perform one of the following actions:
	 
	 1.	Save the form - If everything is correct call [form saveForm]
	 
	 2.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
	 
	 
	 */	
	
	// default does no checking and proceeds to share
	[form saveForm];
}



#pragma mark -
#pragma mark Implementation

- (void)show
{
    [self tryToSend];
}

// Send the share item to the server
- (BOOL)send
{	
    [self sendDidStart];
	NSString *serverPath = @"/";
    if (item.shareType == SHKShareTypeImage) {
        if (!item.filename) {
            item.filename = [item.title stringByAppendingPathExtension:@"jpg"];
        }
        NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/preview.jpg"];
        [UIImageJPEGRepresentation(item.image, 1.0) writeToFile:jpgPath atomically:YES];
        [item setCustomValue:jpgPath forKey:@"localPath"];
        serverPath = @"/Photos";
    } else if (item.data) {
        NSString *tmpPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
        tmpPath = [tmpPath stringByAppendingPathComponent:[item.filename lastPathComponent]];
        [item.data writeToFile:tmpPath atomically:YES];
        [item setCustomValue:tmpPath forKey:@"localPath"];
    }
    [self.restClient uploadFile:item.filename
                         toPath:serverPath
                  withParentRev:nil 
                       fromPath:[item customValueForKey:@"localPath"] ];
    [self retain];
    return YES;
}

#pragma mark - RestClient


- (DBRestClient*)restClient {
    if (restClient == nil) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

#pragma mark - RestClient Delegate functions

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    [self sendDidFinish];
    [self release];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [self sendDidFailWithError:error];
    [self release];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    [self promptAuthorization];
}

@end
