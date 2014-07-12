//  Created by «FULLUSERNAME» on «DATE».

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


/*

 For a step by step guide to creating your service class, start at the top and move down through the comments.
 
 It is strongly recommended you read 'Understanding the share flow' documentation for a brief overview
 of how a service works: http://getsharekit.com/docs/#flow
 
 If your service requires any apikeys, open DefaultSHKConfigurator.m and add methods for them so user can easily
 fill them out. Open the file to see examples of other services using api keys.
 
*/


«OPTIONALHEADERIMPORTLINE»

@implementation «FILEBASENAMEASIDENTIFIER»


#pragma mark -
#pragma mark Configuration : Service Defination

// Enter the name of the service
+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Name of Web Service");
}


// What types of content can the action handle?

// If the action can handle URLs, uncomment this section
/*
 + (BOOL)canShareURL
 {
 return YES;
 }
 */

// Does the service need to shorten URL before sharing? If YES, uncomment this section. Do not forget to setup bit.ly credentials in your configurator. Otherwise the URL simply will not be shortened
/*
 - (BOOL)requiresShortenedURL {
 
 return YES;
 }
 */

// If the action can handle images, uncomment this section
/*
 + (BOOL)canShareImage
 {
 return YES;
 }
 */

// If the action can handle text, uncomment this section
/*
 + (BOOL)canShareText
 {
 return YES;
 }
 */

// If the action can handle files, uncomment this section
/*
 + (BOOL)canShareFile
 {
 return YES;
 }
 */


// Does the service require a login?  If for some reason it does NOT, uncomment this section:
/*
+ (BOOL)requiresAuthentication
{
	return NO;
}
*/

#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Uncomment and change if you need to dynamically enable/disable the action.  (For example if it only works with specific hardware)
/*
+ (BOOL)canShare
{
	return YES;
}
 */

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
- (FormControllerCallback)authorizationFormValidate
{
	// make sure to always call weakself in this block, to avoid retain cycle (currently the sharer retains the form, and the form retains this block
    __weak typeof(self) weakSelf = self;
    
    FormControllerCallback result = ^(SHKFormController *form) {
        
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
	
	
	// Here is an example.  
	// This example assumes the form created by authorizationFormFields had a username and password field.
	 
	// Get the form data
	NSDictionary *formValues = [form formValues];
	 
	// 1. Validate the form data	 
	if ([formValues objectForKey:@"username"] == nil || [formValues objectForKey:@"password"] == nil)
	{
		// display an error
		[[[UIAlertView alloc] initWithTitle:@"Login Error"
                                    message:@"You must enter a username and password"
                                   delegate:nil
                          cancelButtonTitle:@"Close"
                          otherButtonTitles:nil] show];

	}
	
	// 2. Authenticate the user with the web service
	else 
	{
		// Show the activity spinner
		[[SHKActivityIndicator currentIndicator] displayActivity:@"Logging In..."];
	
		// Retain the form so we can access it after the request finishes
		weakSelf.pendingForm = form;
	
		// -- Send a request to the server
		// See http://getsharekit.com/docs/#requests for documentation on using the SHKRequest and SHKEncode helpers
	
		// Set the parameters for the request
		NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@",
							SHKEncode([formValues objectForKey:@"username"]),
							SHKEncode([formValues objectForKey:@"password"])
							];
	
		// Send request
		[SHKRequest startWithURL:[NSURL URLWithString:@"http://api.example.com/auth/"]
													params:params
											 method:@"POST"
                      completion:^(SHKRequest *request) {
                          
                          //This code is handling the request's response
                          
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
                              
                              //for parsing XML responses you can use convenient SHKXMLResponseParser
                              
                              //you should distinguish between bad credentials, and other error. In this example the service returns 401 when bad credentials. The services might differ, so make sure to check the service's API and test it. Your duty is only to check response and call appropriate builtin method. These method notify the delegate and show builtin alerts. Also, do not forget to notify the delegate by calling authDidFinish:
                              
                              if (aRequest.response.statusCode == 401)
                              {
                                  [weakSelf authShowBadCredentialsAlert];
                              }
                              else
                              {
                                  [weakSelf authShowOtherAuthorizationErrorAlert];
                              }
                          }
                          [weakSelf authDidFinish:aRequest.success];

                      }];
	}
        
    };
    return result;
}

#pragma mark -
#pragma mark Share Form

// If you have a share form the user will have the option to skip it in the future.
// If your form has required information and should never be skipped, uncomment this section.
/*
 + (BOOL)canAutoShare
 {
 return NO;
 }
 */

// If your action has options or additional information it needs to get from the user
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

// Optionally validate the user input on the share form. You should override (uncomment) this only if you need to validate any data before sending. There are two ways to validate user input: set validationBlock for particular field (in SHKFormFieldSettings), or shareFormValidate method bellow. The latter is useful when you have to check multiple field's data at once, or have to validate any field asynchronously over network.
/*
 - (FormControllerCallback)shareFormValidate
 {
 
 // make sure to always call weakself in this block, to avoid retain cycle (currently the sharer retains the form, and the form retains this block
__weak typeof(self) weakSelf = self;

 FormControllerCallback result = ^(SHKFormController *form) {
 
 You can get a dictionary of the field values from [form formValues]
 
 You should perform one of the following actions:
 
 1.	Save the form - If everything is correct call
 
 [form saveForm]
 
 2.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
 };
 }
 */

#pragma mark -
#pragma mark Implementation

// When an attempt is made to share the item, this method should be called (in send method, see bellow) to verify that it has everything it needs, otherwise display the share form. Optionally you can override the method, if you need check something else than the default implementation does.
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
     -  after the action completes, handle the response in isFinishedSelector: method.
    */ 
	
	
	// Here is an example.  
	// This example is for a service that can share a URL
	 
	 
	// Determine which type of share to do
	if (item.shareType == SHKShareTypeURL) // sharing a URL
	{
		// Set the parameters for the request
		NSString *params = [NSMutableString stringWithFormat:@"username=%@&password=%@url=%@&title=%@",
							SHKEncode([self getAuthValueForKey:@"username"]), // retrieve the username stored by the authorization form
							SHKEncode([self getAuthValueForKey:@"password"]), // retrieve the password stored by the authorization form
							SHKEncodeURL(item.url),
							SHKEncode(item.title)
							];
		
		// Send request
		[SHKRequest startWithURL:[NSURL URLWithString:@"http://api.example.com/share/"]
                          params:params
                          method:@"POST"
                      completion:^(SHKRequest *request) {
                          /*
                          This block handles the SHKRequest response and should be implemented - your duty is to check the response and decide, if send finished OK, or what kind of error there is. Depending on the result, you should call one of these methods:
                              
                              [self sendDidFinish]; (if successful)
                          [self shouldReloginWithPendingAction:SHKPendingSend]; (if credentials saved in app are obsolete - e.g. user might have changed password, or revoked app access - this will prompt for new credentials and silently share after successful login)
                          [self shouldReloginWithPendingAction:SHKPendingShare]; (if credentials saved in app are obsolete - e.g. user might have changed password, or revoked app access - this will prompt for new credentials and present share UI dialogue after successful login. This can happen if the service always requires to check credentials prior send request)
                          [self sendShowSimpleErrorAlert]; (in case of other error)
                          [self sendDidCancel];(in case of user cancelled - you might need this if the service presents its own UI for sharing)
                           
                           here is example implementation:
                           */
                          
                          if (request.success)
                          {
                              [self sendDidFinish];
                          }
                          else
                          {
                              // See http://getsharekit.com/docs/#requests for documentation on SHKRequest
                              // SHKRequest contains three properties that may assist you in responding to errors:
                              // aRequest.response is the NSHTTPURLResponse of the request
                              // aRequest.response.statusCode is the HTTTP status code of the response
                              // [aRequest getResult] returns a NSString of the body of the response
                              // aRequest.headers is a NSDictionary of all response headers
                              
                              //for parsing XML responses you can use convenient SHKXMLResponseParser
                              
                              //you should distinguish between bad credentials, and other error. In this example the service returns 403 when bad credentials. The services might differ, so make sure to check the service's API and test it.
                              
                              if (request.response.statusCode == 403)
                              {
                                  [self shouldReloginWithPendingAction:SHKPendingSend];
                              }
                              else
                              {
                                  [self sendShowSimpleErrorAlert];
                              }
                          }


                      }];
        
        // if you are uploading a file, make sure you report upload progress using. Do not forget also to implement cancel method, and call [self sendDidCancel] in its implementation too.
        [self showUploadedBytes:totalBytesWritten totalBytes:totalBytesExpectedToWrite];
		
		// Notify self and it's delegates that we started
		[self sendDidStart];
		
		return YES; // we started the request
	}
}

@end
