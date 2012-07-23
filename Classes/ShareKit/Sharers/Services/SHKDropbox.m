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

+ (void)flushAccessToken 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSHKDropboxUserId];
    [defaults removeObjectForKey:kSHKDropboxAccessTokenKey];
    [defaults removeObjectForKey:kSHKDropboxExpiryDateKey];
    [defaults synchronize];
}

#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return @"Dropbox";
}


// What types of content can the action handle?

// If the action can handle URLs, uncomment this section
/*
 + (BOOL)canShareURL
 {
 return YES;
 }
 */

// If the action can handle images, uncomment this section
+ (BOOL)canShareImage
{
    return YES;
}

// If the action can handle text, uncomment this section
/*
 + (BOOL)canShareText
 {
 return YES;
 }
 */

// If the action can handle files, uncomment this section
+ (BOOL)canShareFile
{
    return YES;
}


// Does the service require a login?  If for some reason it does NOT, uncomment this section:
+ (BOOL)requiresAuthentication
{
    return YES;
}


#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the service.  (For example if it only works with specific hardware)
+ (BOOL)canShare
{
	return YES;
}



#pragma mark -
#pragma mark Authentication


#define SHKYourServiceNameCallbackUrl @""	// The user defined callback url

- (id)init
{
	if (self = [super init])
	{		
		self.consumerKey = SHKCONFIG(dropboxConsumerKey);		
		self.secretKey = SHKCONFIG(dropboxSecretKey);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKYourServiceNameCallbackUrl];
		
		
		// -- //
		
		
		// Edit these to provide the correct urls for each oauth step
	    self.requestURL = [NSURL URLWithString:@"https://api.dropbox.com/1/oauth/request_token"];
	    self.authorizeURL = [NSURL URLWithString:@"https://www.dropbox.com/1/oauth/authorize"];
	    self.accessURL = [NSURL URLWithString:@"https://api.dropbox.com/1/oauth/access_token"];
		
		// Allows you to set a default signature type, uncomment only one
		self.signatureProvider = [[[OAHMAC_SHA1SignatureProvider alloc] init] autorelease];
		//self.signatureProvider = [[[OAPlaintextSignatureProvider alloc] init] autorelease];
	}	
	return self;
}

- (BOOL)isAuthorized
{	
    if (![DBSession sharedSession]) {
        [self promptAuthorization];
    }
	return [[DBSession sharedSession] isLinked];
}


- (void)promptAuthorization{
    
    NSString *root = kDBRootDropbox; // Should be set to either kDBRootAppFolder or kDBRootDropbox
    // You can determine if you have App folder access or Full Dropbox along with your consumer key/secret
    // from https://dropbox.com/developers/apps 
    
    
    NSString* errorMsg = nil;
    if ([self.consumerKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app key correctly";
    } else if ([self.secretKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound) {
        errorMsg = @"Make sure you set the app secret correctly";
    } else if ([root length] == 0) {
        errorMsg = @"Set your root to use either App Folder of full Dropbox";
    } 
    
    DBSession* session = 
    [[DBSession alloc] initWithAppKey:self.consumerKey appSecret:self.secretKey root:root];
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
        [[DBSession sharedSession] linkFromController:self];
    }
    [self retain];
}

- (void) authComplete 
{
	if (self.item) 
		[self share];
}

+ (void)logout
{
    [self flushAccessToken];
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

// When an attempt is made to share the item, verify that it has everything it needs, otherwise display the share form
/*
 - (BOOL)validateItem
 { 
 // The super class will verify that:
 // -if sharing a url	: item.url != nil
 // -if sharing an image : item.image != nil
 // -if sharing text		: item.text != nil
 // -if sharing a file	: item.data != nil
 
 return [super validateItem];
 }
 */

- (void)show
{
    [self tryToSend];
}


// Send the share item to the server
- (BOOL)send
{	
    //	if (![self validateItem])
    //		return NO;
	NSString *serverPath = @"/";
    if (item.shareType == SHKShareTypeImage) {
        NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/preview.jpg"];
        [UIImageJPEGRepresentation(item.image, 1.0) writeToFile:jpgPath atomically:YES];
        [item setCustomValue:jpgPath forKey:@"localPath"];
        serverPath = @"/Photos";
    }
    //[item.title stringByAppendingPathExtension:@"jpg"] 
    NSLog(@"Sending to Dropbox");
    // TODO: load filename from item info
    [self.restClient uploadFile:[item.title stringByAppendingPathExtension:@"jpg"]
                         toPath:serverPath
                  withParentRev:nil 
                       fromPath:[item customValueForKey:@"localPath"] ];
    [self sendDidStart];
    [self retain];
    return YES;
}

// This is a continuation of the example provided in 'send' above.  It handles the OAAsynchronousDataFetcher response
// This is not a required method and is only provided as an example
/*
 - (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
 {	
 if (ticket.didSucceed)
 {
 // The send was successful
 [self sendDidFinish];
 }
 
 else 
 {
 // Handle the error
 
 // If the error was the result of the user no longer being authenticated, you can reprompt
 // for the login information with:
 // [self sendDidFailShouldRelogin];
 
 // Otherwise, all other errors should end with:
 [self sendDidFailWithError:[SHK error:@"Why it failed"] shouldRelogin:NO];
 }
 }
 - (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
 {
 [self sendDidFailWithError:error shouldRelogin:NO];
 }
 */

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
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    [self sendDidFailWithError:error];
    [self release];
    NSLog(@"File upload failed with error - %@", error);
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    [self promptAuthorization];
}

@end
