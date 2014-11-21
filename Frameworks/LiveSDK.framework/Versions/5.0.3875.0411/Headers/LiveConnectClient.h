//
//  LiveConnectClient.h
//  Live SDK for iOS
//
//  Copyright 2014 Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LiveAuthDelegate.h"
#import "LiveConnectSession.h"
#import "LiveDownloadOperation.h"
#import "LiveDownloadOperationDelegate.h"
#import "LiveOperationDelegate.h"
#import "LiveUploadOperationDelegate.h"
#import "LiveUploadOverwriteOption.h"

// LiveConnectClient class represents a client object that helps the app to access Live services
// on the user behalf. LiveConnectClient class provides two groups of methods:
// authentication/authorization methods, and data access methods.
// The authentication/authorization methods include init* methods, login* methods
// and logout* methods.
// The data access methods include get* methods, delete* methods, post* methods, put* methods, 
// copy* methods, move* methods, upload* methods and download* methods.
@interface LiveConnectClient : NSObject 

// The user's current session object.
@property(nonatomic, readonly) LiveConnectSession *session;

#pragma mark - init* methods

// init* methods are async methods used to initialize a new instance of LiveConnectClient class.
// An instance of LiveConnectClient class must be initialized via one of the init* methods before
// other methods can be invoked. Invoking any methods other than init* on an uninitialized instance
// will receive an exception. Invoking any init* methods on an instance of LiveConnectClient class 
// that is already initialized will be silently ignored. 
// The initialization process will retrieve the user authentication session using a refresh token
// persisted in the device if available. 
//
// Parameters:
// - clientId: Required. The Client Id value of the app when registered on https://manage.dev.live.com
// - delegate: Optional. An app class instance that implements the LiveAuthDelegate protocol.
//   Note: Only authCompleted:session:userState of the protocol method will be invoked.
// - scopes: Optional. An array of scopes value that determines the initialization scopes. 
//   Note: The app may retrieve the app session during initialization process. The scopes value will be
//         passed to the Live authentication server, which will return a user session with access token
//         if the authenticated user has already consented the scopes passed in to the app. Otherwise, 
//         the server will reject to send back authentication session data.
// - userState: Optional. An object that is used to track asynchronous state. The userState object will 
//         be passed as userState parameter when any LiveAuthDelegate protocol method is invoked.

- (id) initWithClientId:(NSString *)clientId
               delegate:(id<LiveAuthDelegate>)delegate;

- (id) initWithClientId:(NSString *)clientId
               delegate:(id<LiveAuthDelegate>)delegate
              userState:(id)userState;

- (id) initWithClientId:(NSString *)clientId
                 scopes:(NSArray *)scopes
               delegate:(id<LiveAuthDelegate>)delegate;

- (id) initWithClientId:(NSString *)clientId
                 scopes:(NSArray *)scopes
               delegate:(id<LiveAuthDelegate>)delegate
              userState:(id)userState;

#pragma mark - login* methods

// login* methods are async methods used to present a modal window and show login and authorization forms so 
// that the user can login with his/her Microsoft account and authorize the app to access the Live services on
// the user behalf. 
// If the current user session already satisfies the scopes specified in the parameter, the delegate method
// authCompleted:session:userState will be invoked right away.
// At any time, only one login* method can be invoked. If there is a pending login* process ongoing, a call to 
// a login* method will receive an exception.
// Parameters:
// - currentViewController: Required. The current UIViewController that will present login UI in a modal window.
// - delegate: Optional. An app class instance that implements the LiveAuthDelegate protocol.
// - scopes: Optional. An array of scopes value for the user to authorize. If the scopes value is missing, the 
//           scopes value passed in via the init* method will be used. If neither the init* method nor the login* 
//           method has a scope value, the call will receive an exception.  
// - userState: Optional. An object that is used to track asynchronous state. The userState object will be 
//           passed as userState parameter when any LiveAuthDelegate protocol method is invoked.

- (void) login:(UIViewController *)currentViewController
      delegate:(id<LiveAuthDelegate>)delegate;

- (void) login:(UIViewController *)currentViewController
      delegate:(id<LiveAuthDelegate>)delegate
     userState:(id)userState;

- (void) login:(UIViewController *)currentViewController
        scopes:(NSArray *)scopes
      delegate:(id<LiveAuthDelegate>)delegate;

- (void) login:(UIViewController *)currentViewController
        scopes:(NSArray *)scopes
      delegate:(id<LiveAuthDelegate>)delegate
     userState:(id)userState;

#pragma mark - logout* methods

// logout* methods are async methods used to log out the user from the app.
// Parameters:
// - delegate: Optional. An app class instance that implements the LiveAuthDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object will be 
//             passed as userState parameter when any LiveAuthDelegate protocol method is invoked.

- (void) logout;

- (void) logoutWithDelegate:(id<LiveAuthDelegate>)delegate
                  userState:(id)userState;

#pragma mark - get* methods

// get* methods are async methods used to access Live REST API service using the HTTP GET method.
// Parameters:
// - path: Required. The resource path required to send request to the Live REST API.
// - delegate: Optional. An instance of a class that implements the LiveOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveOperationDelegate protocol method is invoked.

- (LiveOperation *) getWithPath:(NSString *)path
                       delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) getWithPath:(NSString *)path
                       delegate:(id <LiveOperationDelegate>)delegate
                      userState:(id)userState;

#pragma mark - delete* methods

// delete* methods are async methods used to access Live REST API service using the HTTP DELETE method.
// Parameters:
// - path: Required. The resource path required to send request to the Live REST API.
// - delegate: Optional. An instance of a class that implements the LiveOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveOperationDelegate protocol method is invoked.

- (LiveOperation *) deleteWithPath:(NSString *)path
                          delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) deleteWithPath:(NSString *)path
                          delegate:(id <LiveOperationDelegate>)delegate
                         userState:(id)userState;

#pragma mark - put* methods

// put* methods are async methods used to access Live REST API service using the HTTP PUT method.
// Parameters:
// - path: Required. The resource path required to send request to the Live REST API.
// - jsonBody: Required. A NSString instance that includes the request body in Json format.
// - dictBody: Required. A NSDictionary instance that includes the request body attributes.
// - delegate: Optional. An instance of a class that implements the LiveOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveOperationDelegate protocol method is invoked.

- (LiveOperation *) putWithPath:(NSString *)path
                       jsonBody:(NSString *)jsonBody
                       delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) putWithPath:(NSString *)path
                       jsonBody:(NSString *)jsonBody
                       delegate:(id <LiveOperationDelegate>)delegate
                      userState:(id)userState;

- (LiveOperation *) putWithPath:(NSString *)path
                       dictBody:(NSDictionary *)dictBody
                       delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) putWithPath:(NSString *)path
                       dictBody:(NSDictionary *)dictBody
                       delegate:(id <LiveOperationDelegate>)delegate
                      userState:(id)userState;

#pragma mark - post* methods
// post* methods are async methods used to access Live REST API service using the HTTP POST method.
// Parameters:
// - path: Required. The resource path required to send request to the Live REST API.
// - jsonBody: Required. A NSString instance that includes the request body in Json format.
// - dictBody: Required. A NSDictionary instance that includes the request body attributes.
// - delegate: Optional. An instance of a class that implements the LiveOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveOperationDelegate protocol method is invoked.

- (LiveOperation *) postWithPath:(NSString *)path
                        jsonBody:(NSString *)jsonBody
                        delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) postWithPath:(NSString *)path
                        jsonBody:(NSString *)jsonBody
                        delegate:(id <LiveOperationDelegate>)delegate
                       userState:(id)userState;

- (LiveOperation *) postWithPath:(NSString *)path
                        dictBody:(NSDictionary *)dictBody
                        delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) postWithPath:(NSString *)path
                        dictBody:(NSDictionary *)dictBody
                        delegate:(id <LiveOperationDelegate>)delegate
                       userState:(id)userState;

#pragma mark - move* methods

// move* methods are async methods used to access Live REST API service using the HTTP MOVE method.
// A MOVE request is used to move a user's file to a different folder on the user's SkyDrive account.
// Parameters:
// - path: Required. The path or object Id of the resource to be moved.
// - destination: Required. The object Id of the destination folder the resource is going to be moved to.
// - delegate: Optional. that implements the LiveOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveOperationDelegate protocol method is invoked.

- (LiveOperation *) moveFromPath:(NSString *)path
                   toDestination:(NSString *)destination
                        delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) moveFromPath:(NSString *)path
                   toDestination:(NSString *)destination
                        delegate:(id <LiveOperationDelegate>)delegate
                       userState:(id)userState;

#pragma mark - copy* methods
// copy* methods are async methods used to access Live REST API service using the HTTP COPY method.
// A COPY request is used to copy a user's file to a different folder on the user's SkyDrive account.
// Parameters:
// - path: Required. The path or object Id of the resource to be copied.
// - destination: Required. The object Id of the destination folder the resource is going to be copied to.
// - delegate: Optional. An instance of a class that implements the LiveOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveOperationDelegate protocol method is invoked.

- (LiveOperation *) copyFromPath:(NSString *)path
                   toDestination:(NSString *)destination
                        delegate:(id <LiveOperationDelegate>)delegate;

- (LiveOperation *) copyFromPath:(NSString *)path
                   toDestination:(NSString *)destination
                        delegate:(id <LiveOperationDelegate>)delegate
                       userState:(id)userState;

#pragma mark - download* methods

// download* methods are async methods used to download a file from the user's SkyDrive account.
// Parameters:
// - path: Required. The path of the resource to be downloaded.
// - delegate: Optional. An instance of a class that implements the LiveDownloadOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveDownloadOperation instance that will be passed as a parameter 
//           when a LiveDownloadOperationDelegate protocol method is invoked.

- (LiveDownloadOperation *) downloadFromPath:(NSString *)path
                                    delegate:(id <LiveDownloadOperationDelegate>)delegate;

- (LiveDownloadOperation *) downloadFromPath:(NSString *)path
                                    delegate:(id <LiveDownloadOperationDelegate>)delegate
                                   userState:(id)userState;

#pragma mark - upload* methods

// upload* methods are async methods used to upload a file to the user's SkyDrive account.
// Parameters:
// - path: Required. The path of the location where the file should be uploaded to.
// - fileName: Required. The file name that should be used for the file to be 
//         uploaded on Skydrive.
// - overwrite: Optional. An enum value indicating the behavior if there is existing file with the same name in the SkyDrive location.
// - data: Required. The NSData instance that contains the data to upload.
// - inputStream: Required. The NSInputStream instance that is the source of the data to read and upload.
// - delegate: Optional. The instance of a class that implements the LiveUploadOperationDelegate protocol.
// - userState: Optional. An object that is used to track asynchronous state. The userState object can be 
//           found in the userState property of the LiveOperation instance that will be passed as a parameter 
//           when a LiveUploadOperationDelegate protocol method is invoked.

- (LiveOperation *) uploadToPath:(NSString *)path
                        fileName:(NSString *)fileName
                            data:(NSData *)data
                        delegate:(id <LiveUploadOperationDelegate>)delegate;

- (LiveOperation *) uploadToPath:(NSString *)path
                        fileName:(NSString *)fileName
                            data:(NSData *)data
                       overwrite:(LiveUploadOverwriteOption)overwrite
                        delegate:(id <LiveUploadOperationDelegate>)delegate
                       userState:(id)userState;

- (LiveOperation *) uploadToPath:(NSString *)path
                        fileName:(NSString *)fileName
                     inputStream:(NSInputStream *)inputStream
                        delegate:(id <LiveUploadOperationDelegate>)delegate;

- (LiveOperation *) uploadToPath:(NSString *)path
                        fileName:(NSString *)fileName
                     inputStream:(NSInputStream *)inputStream
                       overwrite:(LiveUploadOverwriteOption)overwrite
                        delegate:(id <LiveUploadOperationDelegate>)delegate
                       userState:(id)userState;

@end
