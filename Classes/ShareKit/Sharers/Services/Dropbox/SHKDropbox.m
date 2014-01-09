//
//  SHKDropbox.m
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKDropbox.h"
#import "SharersCommonHeaders.h"

///Where user starts to browse the save location
#define kSHKDropboxStartDirectory @"/"

#define kDropboxMaxFileSize 150000000
#define kSHKDropboxSizeChunks 104800
#define kDropboxErrorDomain @"dropbox.com"
#define kDropboxDomain @"www.dropbox.com"
#define kDropboxResourseDomain  @"dl.dropbox.com"

static NSString *const kSHKDropboxUserInfo =@"SHKDropboxUserInfo";
static NSString *const kSHKDropboxParentRevision =@"SHKDropboxParentRevision";
static NSString *const kSHKDropboxStoredFileName =@"SHKDropboxStoredFileName";

@interface SHKDropbox () {
    long long   __fileOffset;
    long long   __fileSize;
    BOOL        _startSending;
}

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) UIAlertView *authAlert;
@property (nonatomic, strong) UIAlertView *overwriteAlert;

+ (DBSession *) createNewDropbox;
+ (DBSession *) dropbox;

@end

@implementation SHKDropbox

#pragma mark - Memory

- (void)dealloc
{
    [_restClient cancelAllRequests];
    
    [DBRequest setNetworkRequestDelegate:nil];
    _restClient.delegate = nil;
    
    if ([DBSession sharedSession].delegate == self) {
        [[DBSession sharedSession] setDelegate:nil];
        [DBSession setSharedSession:nil];
    }
}

#pragma mark - Dropbox object
//in case of using DropboxFramework by other part of App
+ (DBSession *) createNewDropbox {
    
    NSString* appKey = SHKCONFIG(dropboxAppKey);
    NSString* appSecret = SHKCONFIG(dropboxAppSecret);
    NSString *root = SHKCONFIG(dropboxRootFolder);
    
    //Just to remind the developer
    NSString* errorMsg = nil;
    if ([appKey rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound)
    {
        errorMsg = @"SHKCONFIG - Make sure you set the app key correctly";
    }
    else if ([appSecret rangeOfCharacterFromSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]].location != NSNotFound)
    {
        errorMsg = @"SHKCONFIG - Make sure you set the app secret correctly";
    }
    else if ([root length] == 0)
    {
        errorMsg = @"SHKCONFIG - Set your root to use either App Folder of full Dropbox";
    }
    else
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
        NSDictionary *loadedPlist =
        [NSPropertyListSerialization
         propertyListFromData:plistData mutabilityOption:0 format:NULL errorDescription:NULL];
        NSDictionary *urlTypes = [loadedPlist objectForKey:@"CFBundleURLTypes"];
        NSString *scheme = nil;
        
        for (NSDictionary *schemeDict in urlTypes) {
            if ([schemeDict isKindOfClass:[NSDictionary class]] == YES && [@"Dropbox" isEqualToString:[schemeDict objectForKey:@"CFBundleTypeRole"]] == YES) {
                scheme = [[schemeDict objectForKey:@"CFBundleURLSchemes"] lastObject];
                break;
            }
        }
        if ([[scheme class] isSubclassOfClass:[NSString class]] == NO || scheme.length < 1 || [scheme hasPrefix:@"db-"] == NO || [scheme isEqualToString:@"db-APP_KEY"] == YES) {
            errorMsg = @"Setup Dropbox URL-scheme correctly in ShareKit-Info.plist";
        }
    }
    
    if (errorMsg != nil)
    {
        [[[UIAlertView alloc]
           initWithTitle:@"Error Configuring Session" message:errorMsg
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
         show];
        return nil;
    }
    //End reminder
    
//    http://stackoverflow.com/a/11261164/812678
    DBSession* session =[[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    session.delegate = nil; 
    [DBSession setSharedSession:session];
    return session;
}
+ (DBSession *) dropbox
{
    if (![DBSession sharedSession]) {
        return [SHKDropbox createNewDropbox];
    }
    return [DBSession sharedSession];
}
- (DBRestClient *)restClient {
    if (!_restClient) {
        DBRestClient *client = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient = client;
        self.restClient.delegate = self;
    }
    return _restClient;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"Dropbox"); }

+ (BOOL)canGetUserInfo { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file { return YES; }

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL) shouldOverwrite {
    return [SHKCONFIG(dropboxShouldOverwriteExistedFile) boolValue];
}

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{
    return [[SHKDropbox dropbox] isLinked];
}

- (void)promptAuthorization
{
    if (![[SHKDropbox dropbox] isLinked]) {
        DBSession *dropbox = [SHKDropbox dropbox];
        if (dropbox.delegate && dropbox.delegate != self) {
            dropbox = [SHKDropbox createNewDropbox];
        }
        dropbox.delegate = self;

        [DBRequest setNetworkRequestDelegate:self];

        [self saveItemForLater:SHKPendingShare];
        
        [[SHK currentHelper] keepSharerReference:self]; // DBSession doesn't retain delegates
        [dropbox linkFromController:[[SHK currentHelper] rootViewForUIDisplay]];
    }
}

#pragma mark - Handle authorization URL response

+ (void)logout
{
    [[SHKDropbox dropbox] unlinkAll];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKDropboxUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)username {
    
    NSData *userInfoData = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKDropboxUserInfo];
    DBAccountInfo *accountInfo = [NSKeyedUnarchiver unarchiveObjectWithData:userInfoData];
    NSString *result = accountInfo.displayName;
    return result;
}

+ (BOOL) handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        SHKDropbox *dropboxSharer = (SHKDropbox *)[DBSession sharedSession].delegate;
        if (!dropboxSharer || ![dropboxSharer isKindOfClass:[SHKDropbox class]]) {
            dropboxSharer = [[SHKDropbox alloc] init];
            DBSession *dropbox = [SHKDropbox dropbox];
            [dropbox setDelegate:dropboxSharer];
        }
        [dropboxSharer checkURL:url];
        return TRUE;
    }
    return FALSE;
}

// Just to keep watch dog out
- (void) checkURL:(NSURL *)url {
    if ([[DBSession sharedSession] isLinked])
    {
        //  check url
        //  if user has pressed "Cancel" in dialogue, url = "db-APP-KEY://API_VERSION/cancel"
        
        if ([[url absoluteString] rangeOfString:@"cancel"].length > 0 && [[url absoluteString] rangeOfString:[NSString stringWithFormat:@"db-%@", SHKCONFIG(dropboxAppKey)]].length > 0) {
            [[[UIAlertView alloc]
               initWithTitle:@"Dropbox" message:SHKLocalizedString(@"Sorry, %@ encountered an error. Please try again.", [self sharerTitle])  delegate:self
               cancelButtonTitle:SHKLocalizedString(@"Cancel") otherButtonTitles:SHKLocalizedString(@"Continue"), nil]
             show];
            return;
        }
        // error code 401: Bad or expired token. This can happen if the user or
        // Dropbox revoked or expired an access token. To fix, you should
        // re-authenticate the user.
        else if ([[url absoluteString] rangeOfString:[NSString stringWithFormat:@"%@ error", kDropboxErrorDomain]].location != NSNotFound)
        {
            [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
            [[DBSession sharedSession] unlinkAll];
            [self performSelector:@selector(authorize) withObject:nil afterDelay:0.1]; //Avoid exception with animation conflicts between SDK and SHK UIs
            return;
        }
        else
        {
            //start upload logic for pending share
            [self restoreItem];
            [self authDidFinish:TRUE];
            
            if (self.item)
                [self performSelector:@selector(tryPendingAction) withObject:nil afterDelay:0.6]; //Let Oauth login view dismiss
        }
    } else {
        [self authDidFinish:NO];
        [self performSelector:@selector(SHKDropboxDidCansel) withObject:nil afterDelay:0.5]; //Avoid exception with animation conflicts between SDK and SHK UIs
    }
}

#pragma mark - UI

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
    
    if (type == SHKShareTypeUserInfo) return nil;
    
    NSString *startDir = kSHKDropboxStartDirectory;
    SHKFormFieldOptionPickerSettings *directoryField = [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Path")
                                                                                           key:kSHKDropboxDestinationDir
                                                                                         start:startDir
                                                                                   pickerTitle:SHKLocalizedString(@"Dropbox")
                                                                               selectedIndexes:nil
                                                                                 displayValues:nil
                                                                                    saveValues:nil
                                                                                 allowMultiple:NO
                                                                                  fetchFromWeb:YES
                                                                                      provider:self];
    directoryField.pushNewContentOnSelection = YES;
    return @[directoryField];
}

#pragma mark - SHKFormOptionControllerOptionProvider delegate methods

- (void)SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController *)optionController {
    
	self.curOptionController = optionController;
    
    if (optionController.selectionValue) {
        [self.restClient loadMetadata:optionController.selectionValue];
    } else {
        [self.restClient loadMetadata:optionController.settings.start];
    }
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController *)optionController {
    
    //TODO: cancel all requests
	//NSAssert(self.curOptionController == optionController, @"there should never be more than one picker open.");
	//[self.getGroupsFetcher cancel];
}

#pragma mark - Share form validation (check metadata - if file exists on Dropbox)

- (FormControllerCallback)shareFormValidate {
    
    __weak typeof(self) weakSelf = self;
    
    FormControllerCallback result =  ^(SHKFormController *form) {
        
        // Display an activity indicator
        if (!weakSelf.quiet)
            [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Connecting...")];
        
        self.pendingForm = form;
        
        NSString *dropboxFileName = [weakSelf.item.file.filename normalizedDropboxPath];
        [self.item setCustomValue:dropboxFileName forKey:kSHKDropboxStoredFileName];
        
        NSDictionary *formValues = [form formValues];
        
        NSString *destinationDir = [formValues objectForKey:kSHKDropboxDestinationDir];
        if (![destinationDir hasSuffix:@"/"]) {
            destinationDir = [destinationDir stringByAppendingString:@"/"];
        }
        
        NSString *remoteFilePath = [destinationDir stringByAppendingString:dropboxFileName];
        
        [self startLoadMetadataForPath:remoteFilePath withHash:nil];
        [[SHK currentHelper] keepSharerReference:self];
    };
    return result;
}

//TODO: is this method needed? We can call restClient directly...
- (void) startLoadMetadataForPath:(NSString *)path withHash:(NSString *) remoteHash {
    
    DBRestClient *restClient = [self restClient];
    [restClient setDelegate:self];
    [DBRequest setNetworkRequestDelegate:self];
    if (remoteHash.length > 0) {
        [restClient loadMetadata:path withHash:remoteHash];
    } else {
        [restClient loadMetadata:path];
    }
}

#pragma mark - DBRestClientDelegate methods (Metadata)

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    
    [[SHK currentHelper] removeSharerReference:self];
    if (!_startSending) {
        [[SHKActivityIndicator currentIndicator] hide];
    }
    
    if (metadata && metadata.path.length > 0) {
        
        if (metadata.isDirectory) {//user chooses directory within form option controller
            
            NSMutableArray *directoriesDisplay = [[NSMutableArray alloc] initWithCapacity:3];
            NSMutableArray *directoriesSave = [[NSMutableArray alloc] initWithCapacity:3];
            
            for (DBMetadata *contentMetadata in metadata.contents) {
                if (contentMetadata.isDirectory) {
                    [directoriesDisplay addObject:contentMetadata.filename];
                    [directoriesSave addObject:contentMetadata.path];
                }
            }
            [self.curOptionController optionsEnumeratedDisplay:directoriesDisplay save:directoriesSave];
            return;
        }
        
        if ([[metadata.path lastPathComponent] isEqualToDropboxPath:[self.item customValueForKey:kSHKDropboxStoredFileName]]) { //form validation detected file exists (or existed) on Dropbox
            
            [self.item setCustomValue:metadata.rev forKey:kSHKDropboxParentRevision];
            
            if ([self shouldOverwrite] || metadata.isDeleted) {
                
                [self.pendingForm saveForm]; //start sharing
                
            } else {
                
                self.overwriteAlert = [[UIAlertView alloc] initWithTitle:[[self class] sharerTitle]
                                           message:SHKLocalizedString(@"Do you want to overwrite existing file in %@?", [[self class] sharerTitle])
                                          delegate:self
                                 cancelButtonTitle:SHKLocalizedString(@"Cancel")
                                 otherButtonTitles:@"OK", nil];
                [self.overwriteAlert show];
            }
        }
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    
    if (!_startSending) {
        [[SHKActivityIndicator currentIndicator] hide];
    }
    
    if ([error.domain isEqualToString:kDropboxErrorDomain] == YES && error.code == 404) {
        //[self startSendingStoredObject];
        [[self pendingForm] saveForm];
    } else {
        [self checkDropboxAPIError:error];
    }
}

#pragma mark - Send

- (BOOL) send
{
	if (self.item.shareType == SHKShareTypeImage) {
        
        [self.item convertImageShareToFileShareOfType:SHKImageConversionTypePNG quality:0];
    }
    
    if (![self validateItem]) return NO;
    
    _startSending = FALSE;

    if (self.item.shareType == SHKShareTypeFile) {
        
        [self startSendingStoredObject];
        
    } else if (self.item.shareType == SHKShareTypeUserInfo) {
        
        self.quiet = YES;
        [self.restClient loadAccountInfo];
        [[SHK currentHelper] keepSharerReference:self];
        [self sendDidStart];
		return TRUE;
    }
	
	return NO;
}

#pragma mark - DBRestClientDelegate methods (loadAccountInfo)

- (void)restClient:(DBRestClient*)client loadedAccountInfo:(DBAccountInfo*)info {
    
    SHKLog(@"dropboxUserInfo %@ saved to defaults", [info description]);
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:info];    // obj is the data object we want to put into NSUserDefaults.
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kSHKDropboxUserInfo];
    [self sendDidFinish];
    //must be postponed, otherwise dropbox-ios-sdk v1.3.9 crashes
    [[SHK currentHelper] performSelector:@selector(removeSharerReference:) withObject:self afterDelay:0.5];
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error; {
    
    SHKLog(@"loadUserInfo failed with error: %@", [error description]);
    //must be postponed, otherwise dropbox-ios-sdk v1.3.9 crashes
    [[SHK currentHelper] performSelector:@selector(removeSharerReference:) withObject:self afterDelay:0.5];
}

//  https://www.dropbox.com/developers/start/files#ios
//  to get callback from DBRestClient you should use MainThread or
//  thread with runloop
- (void) startSendingStoredObject {

    DBRestClient *restClient = [self restClient];
    [restClient setDelegate:self];
    [DBRequest setNetworkRequestDelegate:self];

    NSString *localPath = self.item.file.path;
    if (localPath.length < 1) {
        return;
    }
    NSString *destinationDir = [self.item customValueForKey:kSHKDropboxDestinationDir];
    if (destinationDir.length < 1) {
        destinationDir = @"/";
    }
    NSString *fileName = [self.item customValueForKey:kSHKDropboxStoredFileName];
    if (fileName.length < 1) {
        fileName = [localPath lastPathComponent];
    }
    if (fileName.length < 1) {
        return;
    }

    NSInteger fileSize = self.item.file.size;
    if (fileSize < 0) {
        [self SHKDropboxDidFailWithError:[SHK error:SHKLocalizedString(@"There was an error while sharing")]];
    }
    __fileOffset = 0;
    __fileSize = fileSize;
    _startSending = TRUE;
    NSString *parentRev = [self.item customValueForKey:kSHKDropboxParentRevision]; //nil in case of new file

    if (fileSize <= kSHKDropboxSizeChunks) {
        [restClient uploadFile:fileName
                        toPath:destinationDir
                 withParentRev:parentRev
                      fromPath:localPath];
    } else {
        [restClient    uploadFileChunk:nil
                                offset:__fileOffset
                              fromPath:localPath];
    }
    _startSending = TRUE;
}

#pragma mark -  DBNetworkRequestDelegate methods

static int outstandingRequests = 0;

- (void)networkRequestStarted {
    // Notify that we started
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
    //  to avoid case with UI intersection with callback request delegate -
    //  network activity for autorization
    if (_startSending && [self isAuthorized]) {
        [self sendDidStart];
    }
}
- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests <= 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

#pragma mark - DBSessionDelegate methods
- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId {
	
    self.authAlert = [[UIAlertView alloc] initWithTitle:@"Dropbox"
                                 message:SHKLocalizedString(@"Could not authenticate you. Please relogin.")
                                delegate:self
                       cancelButtonTitle:SHKLocalizedString(@"Cancel")
                       otherButtonTitles:SHKLocalizedString(@"Continue"), nil];
    [self.authAlert show];
}

#pragma mark - DBRestClientDelegate methods (upload)

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
//    SHKLog(@"%@ %@ %@ uploaded %@", [client description], destPath, srcPath, [metadata description]);
    [self SHKDropboxGetSharableLink:destPath];
//    [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.01];
}
- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
//    SHKLog(@"%@ %@ %@ upload progress = %.2f %", [client description], destPath,srcPath, progress * 100);
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxUploadProgress object:[NSNumber numberWithFloat:progress]];
}
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    
    [self performSelector:@selector(SHKDropboxDidFailWithError:) withObject:error afterDelay:0.01];
}
- (void)restClient:(DBRestClient *)client uploadedFileChunk:(NSString *)uploadId newOffset:(unsigned long long)offset
          fromFile:(NSString *)localPath expires:(NSDate *)expiresDate {
    __fileOffset = offset;
    if (__fileOffset < __fileSize) {
        [client uploadFileChunk:uploadId offset:__fileOffset fromPath:localPath];
    } else {
        NSString *fileName = [self.item customValueForKey:kSHKDropboxStoredFileName];
        if (fileName.length < 1) {
            fileName = [NSString stringWithFormat:@"ShareKit-file-%lu", random() % 200];
        }
        NSString *destinationDir = [self.item customValueForKey:kSHKDropboxDestinationDir];
        [self.item setCustomValue:localPath forKey:uploadId];
        if (destinationDir.length < 1) {
            destinationDir = @"/";
        }
        NSString *parentRev = [self.item customValueForKey:kSHKDropboxParentRevision];
        [client uploadFile:fileName toPath:destinationDir withParentRev:parentRev fromUploadId:uploadId];
        __fileOffset = 0;
        __fileSize = 0;
    }
}
- (void)restClient:(DBRestClient *)client uploadFileChunkFailedWithError:(NSError *)error {
   
    [self SHKDropboxDidFailWithError:error];
}
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath fromUploadId:(NSString *)uploadId
          metadata:(DBMetadata *)metadata {

//    [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.01];
    [self SHKDropboxGetSharableLink:destPath];
}
- (void)restClient:(DBRestClient *)client uploadFromUploadIdFailedWithError:(NSError *)error {

    [self performSelector:@selector(SHKDropboxDidFailWithError:) withObject:error afterDelay:0.01];
}

#pragma mark - Sharable link
- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path {
    if ([link rangeOfString:kDropboxDomain].length > 0) {
        link = [link stringByReplacingOccurrencesOfString:kDropboxDomain withString:kDropboxResourseDomain];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxSharableLink object:link];
    [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.2];
}
- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxSharableLink object:error];
    [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.2];
}

#pragma mark - Check API Error
- (void) checkDropboxAPIError:(NSError *) error {
    //  Check 401 - Bad or expired token. This can happen if the user or Dropbox
    //  revoked or expired an access token.
    NSInteger dbErrorCode = error.code;
    if ([error.domain isEqual: kDropboxErrorDomain] == YES && (dbErrorCode == 401 || dbErrorCode == 403)) {
        
        [self saveItemForLater:self.pendingAction];
        [[SHKDropbox dropbox] unlinkAll];
        [[[UIAlertView alloc] initWithTitle:[self sharerTitle]
                                     message:SHKLocalizedString(@"Could not authenticate you. Please relogin.")
                                    delegate:self
                           cancelButtonTitle:SHKLocalizedString(@"Cancel")
                           otherButtonTitles:SHKLocalizedString(@"Continue"), nil] show];
    } else {
        NSError *internal = nil;
        if (dbErrorCode == 507) {
            internal = [SHK error:SHKLocalizedString(@"You are over Dropbox storage quota")];
        }
        if (dbErrorCode >= 500 && dbErrorCode < 600 && dbErrorCode != 507) {
            internal = [SHK error:SHKLocalizedString(@"Sorry, %@ encountered an error. Please try again.", [self sharerTitle])];
        }
        if (dbErrorCode == 400) {
            internal = [SHK error:SHKLocalizedString(@"File name is wrong")]; //could be wrong path, or file name, or file name extenition is in Dropbox ignore list
        }
        [self sendDidFailWithError:internal];
        [self stopNetworkIndication];
        [[SHK currentHelper] removeSharerReference:self]; //see [self send]
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if ([alertView isEqual:self.authAlert]) {
        
        if (buttonIndex != alertView.cancelButtonIndex) {
            [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
            [self performSelector:@selector(authorize) withObject:nil afterDelay:0.1]; //Avoid exception with animation conflicts between SDK and SHK UIs
        } else {
            [self SHKDropboxDidCansel];
        }
    
    } else if ([alertView isEqual:self.overwriteAlert]) {
        
        if (buttonIndex == alertView.cancelButtonIndex) {
            [[self pendingForm] cancel];
        } else {
            [self startSendingStoredObject];
        }
    }
}

#pragma mark - Delegate Notifications
- (void) SHKDropboxDidFailWithError:(NSError *) error {
    _startSending = FALSE;

    [[SHKActivityIndicator currentIndicator] hide];
    [self checkDropboxAPIError:error];
}

- (void) SHKDropboxDidFinishSuccess {
    [[SHKActivityIndicator currentIndicator] hide];
    _startSending = FALSE;
    [self sendDidFinish];
    [self stopNetworkIndication];
    [[SHK currentHelper] removeSharerReference:self];
}

- (void) SHKDropboxDidCansel {
    [[SHKActivityIndicator currentIndicator] hide];
    [self stopNetworkIndication];
    _startSending = FALSE;
    [self sendDidCancel];
    [[SHK currentHelper] removeSharerReference:self];
}
- (void) stopNetworkIndication {
    outstandingRequests = 0;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) SHKDropboxGetSharableLink:(NSString *) remotePath {
    if (remotePath.length < 1) {
        [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.1];
    } else {
        NSString *path = [NSString stringWithString:remotePath];
        [[self restClient] loadSharableLinkForFile:path  shortUrl:FALSE];
    }
}

#pragma mark - Description

- (NSString *) description {
    NSString *action = nil;
    switch (self.pendingAction) {
        case SHKPendingNone:
            action = @"SHKPendingNone";
            break;
        case SHKPendingRefreshToken:
            action = @"SHKPendingRefreshToken";
            break;
        case SHKPendingSend:
            action = @"SHKPendingSend";
            break;
        case SHKPendingShare:
            action = @"SHKPendingShare";
            break;
        default:
            break;
    }
    return [NSString stringWithFormat:@"<%@ : %p> SHKPendingAction = %@ SHKItem: {\n    %@  }", [self class], self, action, [self.item description]];
}

@end
