//
//  SHKPinterest.m
//  ShareKit
//
//  Created by Vilém Kurz on 09/05/14.
//
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

#import "SHKPinterest.h"
#import "SharersCommonHeaders.h"

#import "PinterestSDK.h"
#import "PDKPin.h"
#import "PDKUser.h"

static NSString *const SHKPinterestUserInfoKey = @"kSHKPinterestUserInfo";

static NSString *const SHKPinterestParsedUserObjectDataKey = @"data";
static NSString *const SHKPinterestBoardIdField = @"id";
static NSString *const SHKPinterestBoardNameField = @"name";

static NSString *const SHKPinterestBoardCustomItemKey = @"board";

@interface SHKPinterest () <SHKFormOptionControllerOptionProvider>

//a cache used when sharing UIImage
@property NSUInteger imageTotalBytes;

@end

@implementation SHKPinterest

#pragma mark -
#pragma mark - Initialization

+ (void)setupPinterestSDK {
    
    [PDKClient configureSharedInstanceWithAppId:SHKCONFIG(pinterestAppId)];
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [SHKPinterest setupPinterestSDK];
    }
    return self;
}

#pragma mark -
#pragma mark Configuration : Service Definition

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Pinterest"); }

+ (BOOL)canShareItem:(SHKItem *)item {
 
    BOOL isPictureURI = item.URLPictureURI;
    BOOL isImageWithURL = item.image && [self requiresAuthentication]; //image uploads allowed only for fully authenticated users
    BOOL isFileWithURL = [item.file.mimeType hasPrefix:@"image/"] && item.URL && [self requiresAuthentication]; //image uploads allowed only for fully authenticated users;
    
    return isImageWithURL || isPictureURI || isFileWithURL;
}

+ (BOOL)requiresAuthentication {
    
    if ([SHKCONFIG(pinterestAllowUnauthenticatedPins) boolValue]) {
        return NO;
    } else {
        return YES;
    }
}

+ (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized {
    
    BOOL result = [[PDKClient sharedInstance] oauthToken] != nil;
    if (!result) {
        
        [[PDKClient sharedInstance] silentlyAuthenticateWithSuccess:[self authenticationSuccessBlock]
                                                         andFailure:^(NSError *error) {
                                                             [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKPinterestUserInfoKey];
                                                         }];
    }
    
    return result;
}

- (void)authorizationFormShow {
    
    [[PDKClient sharedInstance] authenticateWithPermissions:@[PDKClientReadPublicPermissions,
                                                              PDKClientWritePublicPermissions,
                                                              PDKClientReadPrivatePermissions,
                                                              PDKClientWritePrivatePermissions]
                                                withSuccess:[self authenticationSuccessBlock]
                                                 andFailure:^(NSError *error) {
                                                    SHKLog(@"pinterest auth failure %@", [error description]);
                                                    [self authDidFinish:NO];
    }];
}

- (PDKClientSuccess)authenticationSuccessBlock {
    
    PDKClientSuccess result = ^(PDKResponseObject *responseObject) {
    
        [[NSUserDefaults standardUserDefaults] setObject:responseObject.parsedJSONDictionary[SHKPinterestParsedUserObjectDataKey] forKey:SHKPinterestUserInfoKey];
        [self authDidFinish:YES];
        [self restoreItem];
        [self tryPendingAction];
    };
    return result;
}

+ (void)logout {
    
    [PDKClient clearAuthorizedUser];
    [PDKClient sharedInstance].oauthToken = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHKPinterestUserInfoKey];
}

+ (NSString *)username {
    
    NSString *result = nil;
    NSDictionary *parsedResponseObject = [[NSUserDefaults standardUserDefaults] objectForKey:SHKPinterestUserInfoKey];
    if (parsedResponseObject) {
        PDKUser *userInfo = [PDKUser userFromDictionary:parsedResponseObject];
        result = [[NSString alloc] initWithFormat:@"%@ %@", userInfo.firstName, userInfo.lastName];
    }
    return result;
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    SHKFormFieldLargeTextSettings *descriptionField = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Description") key:@"title" start:self.item.title item:self.item];
    
    if ([SHKPinterest requiresAuthentication]) {
        SHKFormFieldOptionPickerSettings *boardPicker = [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Board")
                                                                                            key:SHKPinterestBoardCustomItemKey
                                                                                          start:SHKLocalizedString(@"Select board")
                                                                                    pickerTitle:SHKLocalizedString(@"Select board")
                                                                                selectedIndexes:nil
                                                                                  displayValues:nil
                                                                                     saveValues:nil
                                                                                  allowMultiple:NO
                                                                                   fetchFromWeb:YES
                                                                                       provider:self];
        boardPicker.validationBlock = ^ (SHKFormFieldOptionPickerSettings *formFieldSettings) {
            
            BOOL result = [formFieldSettings valueToSave].length > 0;
            return result;
        };
        return @[descriptionField, boardPicker];
        
    } else {
        
        return @[descriptionField];
    }
}

#pragma mark -
#pragma mark Implementation

- (BOOL)validateItem {
    
    BOOL result = [super validateItem] && [SHKPinterest canShareItem:self.item];
    return result;
}

- (BOOL) send {
    
    // Make sure that the item has minimum requirements
	if (![self validateItem])
		return NO;
    
    if (![SHKPinterest requiresAuthentication]) {
        self.quiet = YES; //callbacks from Safari are not reliable on PinterestSDK, if the app is not installed. Otherwise activity indicator would spin forever
    }
    
    if ((self.item.image || self.item.file) && [SHKPinterest requiresAuthentication]) {
        
        UIImage *imageToShare = nil;
        
        if (self.item.image) {
            imageToShare = self.item.image;
            NSData *imageData = UIImageJPEGRepresentation(self.item.image, 1.0f);
            self.imageTotalBytes = [imageData length];
        } else {
            imageToShare = [UIImage imageWithData:self.item.file.data];
            self.imageTotalBytes = self.item.file.size;
        }
        
        [[PDKClient sharedInstance] createPinWithImage:imageToShare
                                                  link:self.item.URL
                                               onBoard:[self.item customValueForKey:SHKPinterestBoardCustomItemKey]
                                           description:self.item.title
                                              progress:^(CGFloat percentComplete) {
                                                  
                                                  [self showUploadedBytes:percentComplete*self.imageTotalBytes totalBytes:self.imageTotalBytes];
                                              }
                                           withSuccess:[self pinCreationSuccessBlock]
                                            andFailure:[self pinCreationFailureBlock]];
        
    } else if (self.item.URLPictureURI) {
        
        if ([SHKPinterest requiresAuthentication]) {
            
            [[PDKClient sharedInstance] createPinWithImageURL:self.item.URLPictureURI
                                                         link:self.item.URL
                                                      onBoard:[self.item customValueForKey:SHKPinterestBoardCustomItemKey]
                                                  description:self.item.title
                                                  withSuccess:[self pinCreationSuccessBlock]
                                                   andFailure:[self pinCreationFailureBlock]];
        } else {
            
            [PDKPin pinWithImageURL:self.item.URLPictureURI
                               link:self.item.URL
                 suggestedBoardName:@"board"
                               note:self.item.title
                        withSuccess:[self unauthPinCreationSuccessBlock]
                         andFailure:[self unauthPinCreationFailureBlock]];

        }
        
    }  else {
        
        NSAssert(NO, @"Pinterest can not share this item");
        return NO;
    }
    [self sendDidStart];
    return YES;
}

- (PDKUnauthPinCreationSuccess)unauthPinCreationSuccessBlock {
    
    PDKUnauthPinCreationSuccess result = ^{
        [self sendDidFinish];
    };
    return result;
}

- (PDKUnauthPinCreationFailure)unauthPinCreationFailureBlock {
    
    PDKUnauthPinCreationFailure result = ^(NSError *error) {
        [self sendDidFailWithError:error];
    };
    return result;
}

- (PDKClientSuccess)pinCreationSuccessBlock {
    
    PDKClientSuccess result = ^(PDKResponseObject *responseObject) {
        [self sendDidFinishWithResponse:responseObject.parsedJSONDictionary];
    };
    return result;
}

- (PDKClientFailure)pinCreationFailureBlock {
    
    PDKClientFailure result = ^(NSError *error) {
        [self sendDidFailWithError:error];
    };
    return result;
}

- (void)cancel {
    
    [[[PDKClient sharedInstance] operationQueue] cancelAllOperations];
    [self sendDidCancel];
}

#pragma mark - 
#pragma mark SHKFormOptionControllerOptionProvider

- (void)SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController *)optionController {
    
    NSAssert(self.curOptionController == nil, @"there should never be more than one picker open.");
    self.curOptionController = optionController;
    
    [self displayActivity:SHKLocalizedString(@"Loading...")];
    
    NSSet *boardFields = [[NSSet alloc] initWithObjects:SHKPinterestBoardIdField, SHKPinterestBoardNameField, nil];
    
    [[PDKClient sharedInstance] getAuthenticatedUserBoardsWithFields:boardFields
                                                             success:^(PDKResponseObject *responseObject) {
                                                                 
                                                                 [self hideActivityIndicator];
                                                                 
                                                                 NSDictionary *boardsList = responseObject.parsedJSONDictionary[SHKPinterestParsedUserObjectDataKey];
                                                                 NSMutableArray *displayValues = [[NSMutableArray alloc] initWithCapacity:10];
                                                                 NSMutableArray *saveValues = [[NSMutableArray alloc] initWithCapacity:10];
                                                                 
                                                                 for (NSDictionary *board in boardsList) {
                                                                     [displayValues addObject:board[SHKPinterestBoardNameField]];
                                                                     [saveValues addObject:board[SHKPinterestBoardIdField]];
                                                                 }
                                                                 [self.curOptionController optionsEnumeratedDisplay:displayValues save:saveValues];
                                                             }
                                                          andFailure:^(NSError *error) {
                                                              
                                                              [self hideActivityIndicator];
                                                              
                                                              NSHTTPURLResponse *errorResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                                                              if (errorResponse.statusCode == 401) {
                                                                  
                                                                  //revoked access, login again
                                                                  [self shouldReloginWithPendingAction:SHKPendingShare];
                                                                  
                                                              } else {
                                                                  
                                                                  SHKLog(@"Failed to fetch boards with error:%@", [error debugDescription]);
                                                                  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Failed to fetch boards." forKey:NSLocalizedDescriptionKey];
                                                                  NSError *err = [NSError errorWithDomain:@"PTR" code:1 userInfo:userInfo];
                                                                  [self.curOptionController optionsEnumerationFailedWithError:err];
                                                              }
                                                          }];
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController *)optionController {
    
    [self hideActivityIndicator];
     NSAssert(self.curOptionController == optionController, @"there should never be more than one picker open.");
}

@end
