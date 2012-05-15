//  Created by George Termentzoglou on 3/11/2012.


/*

 For a step by step guide to creating your service class, start at the top and move down through the comments.
 
 It is strongly recommended you read 'Understanding the share flow' documentation for a brief overview
 of how a service works: http://getsharekit.com/docs/#flow
 
 If your service requires any apikeys, open SHKConfig.h and add #define's for them so a user can easily
 fill them out.  Open the file to see examples of other services using api keys.
 
*/


#import "SHKDropbox.h"

@implementation SHKDropbox


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
/*
+ (BOOL)requiresAuthentication
{
	return NO;
}
*/ 


#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Subclass if you need to dynamically enable/disable the action.  (For example if it only works with specific hardware)
+ (BOOL)canShare
{
	return YES;
}



#pragma mark -
#pragma mark Authentication

// Return the form fields required to authenticate the user with the service
+ (NSArray *)authorizationFormFields
{
	// See http://getsharekit.com/docs/#forms for documentation on creating forms
	
	// This example form shows a username and password and stores them by the keys 'username' and 'password'.
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:@"Username" key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:@"Password" key:@"password" type:SHKFormFieldTypePassword start:nil],			
			nil];
}

// Return the footer title to display under the login form
+ (NSString *)authorizationFormCaption
{
	// This should tell the user how to get an account.  Be concise!  The standard format is:
	return SHKLocalizedString(@"Create a free account at %@", @"Example.com"); // This function works like (NSString *)stringWithFormat:(NSString*)format, ... | but translates the 'create a free account' part into any supported languages automatically
}

// Authenticate the user using the data they've entered into the form
- (void)authorizationFormValidate:(SHKFormController *)form
{
	/*
	 This is called when the user taps 'Login' on the login form after entering their information.
	 
	 Supply the necessary logic to validate the user input and authenticate the user.
	 
	 You can get a dictionary of the field values from [form formValues]
	 
	 --
	 
	 A common implementation looks like:
	 
	 1. Validate the form data.  
		- Make sure necessary fields were completed.
		- If there is a problem, display an error with UIAlertView
	 
	 2. Authenticate the user with the web service.
		- Display the activity indicator
		- Send a request to the server
			- If the request fails, display an error
			- If the request is successful, save the form
	*/ 
	
	
	/*
	// Here is an example.  
	// This example assumes the form created by authorizationFormFields had a username and password field.
	 
	// Get the form data
	NSDictionary *formValues = [form formValues];
	 
	// 1. Validate the form data	 
	if ([formValues objectForKey:@"username"] == nil || [formValues objectForKey:@"password"] == nil)
	{
		// display an error
		[[[[UIAlertView alloc] initWithTitle:@"Login Error"
									 message:@"You must enter a username and password"
									delegate:nil
						   cancelButtonTitle:@"Close"
						   otherButtonTitles:nil] autorelease] show];

	}
	
	// 2. Authenticate the user with the web service
	else 
	{
		// Show the activity spinner
		[[SHKActivityIndicator currentIndicator] displayActivity:@"Logging In..."];
	
		// Retain the form so we can access it after the request finishes
		self.pendingForm = form;
	
		// -- Send a request to the server
		// See http://getsharekit.com/docs/#requests for documentation on using the SHKRequest and SHKEncode helpers
	
		// Set the parameters for the request
		NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@",
							SHKEncode([formValues objectForKey:@"username"]),
							SHKEncode([formValues objectForKey:@"password"])
							];
	
		// Send request
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.example.com/auth/"]
													params:params
										   delegate:self
								 isFinishedSelector:@selector(authFinished:)
											 method:@"POST"
										  autostart:YES] autorelease];
	}
	*/														 
}

// This is a continuation of the example provided in authorizationFormValidate above.  It handles the SHKRequest response
// This is not a required method and is only provided as an example
/*
- (void)authFinished:(SHKRequest *)aRequest
{		
	// Hide the activity indicator
	[[SHKActivityIndicator currentIndicator] hide];
	
	// If the result is successful, save the form to continue sharing
	if (aRequest.success)
		[pendingForm saveForm];
	
	// If there is an error, display it to the user
	else
	{
		// See http://getsharekit.com/docs/#requests for documentation on SHKRequest
		// SHKRequest contains three properties that may assist you in responding to errors:
		// aRequest.response is the NSHTTPURLResponse of the request
		// aRequest.response.statusCode is the HTTTP status code of the response
		// [aRequest getResult] returns a NSString of the body of the response
		// aRequest.headers is a NSDictionary of all response headers
		
		[[[[UIAlertView alloc] initWithTitle:@"Login Error"
									 message:@"Your username and password did not match"
									delegate:nil
						   cancelButtonTitle:@"Close"
						   otherButtonTitles:nil] autorelease] show];
	}
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
- (void)shareFormValidate:(SHKCustomFormController *)form
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
	 
	// You only need to implement this if you need to check additional variables.
	 
	// If you return NO, you should probably pop up a UIAlertView to notify the user they missed something.
 
	return [super validateItem];
}
*/

// Send the share item to the server
- (BOOL)send
{	
	// Make sure that the item has minimum requirements
	if (![self validateItem])
		return NO;
	
	/*
	 Enter the necessary logic to share the item here.
	 
	 The shared item and relevant data is in self.item
	 // See http://getsharekit.com/docs/#sending
	 
	 --
	 
	 A common implementation looks like:
	 	 
	 -  Send a request to the server
	 -  call [self sendDidStart] after you start your action
	 -	after the action completes, fails or is cancelled, call one of these on 'self':
		- (void)sendDidFinish (if successful)
		- (void)sendDidFailShouldRelogin (if failed because the user's current credentials are out of date)
		- (void)sendDidFailWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
		- (void)sendDidCancel
	 */ 
	
	
	// Here is an example.  
	// This example is for a service that can share a URL
	 
	 
	// Determine which type of share to do
	/*if (item.shareType == SHKShareTypeURL) // sharing a URL
	{
		// Set the parameters for the request
		NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@url=%@&title=%@",
							SHKEncode([self getAuthValueForKey:@"username"]), // retrieve the username stored by the authorization form
							SHKEncode([self getAuthValueForKey:@"password"]), // retrieve the password stored by the authorization form
							SHKEncodeURL(item.url),
							SHKEncode(item.title)
							];
		
		// Send request
		self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.example.com/share/"]
												 params:params
											   delegate:self
									 isFinishedSelector:@selector(shareFinished:)
												 method:@"POST"
											  autostart:YES] autorelease];
		
		// Notify self and it's delegates that we started
		[self sendDidStart];
		*/
		return YES; // we started the request
	//}
	
	return NO;
}


// This is a continuation of the example provided in authorizationFormValidate above.  It handles the SHKRequest response
// This is not a required method and is only provided as an example
/*
- (void)sendFinished:(SHKRequest *)aRequest
{	
	if (!aRequest.success)
	{
		// See http://getsharekit.com/docs/#requests for documentation on SHKRequest
		// SHKRequest contains three properties that may assist you in responding to errors:
		// aRequest.response is the NSHTTPURLResponse of the request
		// aRequest.response.statusCode is the HTTTP status code of the response
		// [aRequest getResult] returns a NSString of the body of the response
		// aRequest.headers is a NSDictionary of all response headers
		
		if (aRequest.response.statusCode == 401)
		{
			[self sendDidFailShouldRelogin];
			return;
		}
		
		// If there was an error that was not login related, send error along to the delegate
		[self sendDidFailWithError:[SHK error:@"There was a problem sharing"] shouldRelogin:NO];
		return;
	}
	
	[self sendDidFinish];
}
*/

@end
