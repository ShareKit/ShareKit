//
//  SHKDropbox.m
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKDropbox.h"
#import "SharersCommonHeaders.h"

#define kDropboxMaxFileSize 150000000
#define kSHKDropboxSizeChunks 104800
#define kDropboxErrorDomain @"dropbox.com"
#define kDropboxDomain @"www.dropbox.com"
#define kDropboxResourseDomain  @"dl.dropbox.com"

static NSString *const kSHKDropboxUserInfo =@"SHKDropboxUserInfo";
static NSString *const kSHKDropboxParentRevision =@"SHKDropboxParentRevision";
static NSString *const kSHKDropboxStoredFileName =@"SHKDropboxStoredFileName";

typedef enum {
    _isNotChecked  =   0,
    _isStarting    =   1,
    _isChecked     =   2,
} SHKDropboxMetadata;


@interface SHKDropbox () {
    long long   __fileOffset;
    long long   __fileSize;
    BOOL        _startSending;
    SHKDropboxMetadata metadataStatus;
}

@property (nonatomic, strong) DBRestClient *restClient;
+ (DBSession *) createNewDropbox;
+ (DBSession *) dropbox;
- (void) showDropboxForm;

@end

@implementation SHKDropbox
@synthesize restClient = _restClient;
#pragma mark - Memory
- (void)dealloc
{
    [[self restClient] cancelAllRequests];
    [DBRequest setNetworkRequestDelegate:nil];
    self.restClient.delegate = nil;
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

#pragma mark - Handle URL

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
            self.pendingAction = SHKPendingSend;
            
            [self authDidFinish:TRUE];
            
            if (self.item)
                [self tryPendingAction];
        }
    } else {
        [self authDidFinish:NO];
        [self performSelector:@selector(SHKDropboxDidCansel) withObject:nil afterDelay:0.5]; //Avoid exception with animation conflicts between SDK and SHK UIs
    }
}
#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Dropbox");
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file
{
    return YES;
}

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

        [self saveItemForLater:self.pendingAction];
        
        [[SHK currentHelper] keepSharerReference:self]; // DBSession doesn't retain delegates
        [dropbox performSelector:@selector(linkFromController:) withObject:[[SHK currentHelper] rootViewForUIDisplay] afterDelay:0.2]; //Avoid exception with animation conflicts between SDK and SHK UIs
    }
}
+ (void)logout
{
    [[SHKDropbox dropbox] unlinkAll];
}

#pragma mark - Send

- (BOOL) send
{
	if (self.item.shareType == SHKShareTypeImage) {
        
        [self.item convertImageShareToFileShareOfType:SHKImageConversionTypePNG quality:0];
    }
    
    if (![self validateItem]) return NO;
    
    _startSending = FALSE;

    if (self.item.shareType == SHKShareTypeFile)
    {
        metadataStatus = _isNotChecked;

        NSString *destinationDir = [self destinationDir];
        [self.item setCustomValue:destinationDir forKey:kSHKDropboxDestinationDir];
        NSString *dropboxFileName = [self.item.file.filename normalizedDropboxPath];
        [self.item setCustomValue:dropboxFileName forKey:kSHKDropboxStoredFileName];
        NSString *remoteFilePath = [destinationDir stringByAppendingString:dropboxFileName];
        
        [self performSelectorOnMainThread:@selector(startLoadDropboxMetadata:) withObject:remoteFilePath waitUntilDone:FALSE];
        
        [[SHK currentHelper] keepSharerReference:self];
		return TRUE;
    }
	
	return NO;
}

- (NSString *)destinationDir {
    
    //TODO: ask user where to download by traversing his file structure on dropbox  - using optionsController (?)
    NSString *result = [self.item customValueForKey:kSHKDropboxDestinationDir];
    if (result.length < 1) {
        
        if (![[DBSession sharedSession].root isEqualToDropboxPath:@"sandbox"]) {
            result = [[NSString stringWithFormat:@"/%@/", SHKCONFIG(appName)] normalizedDropboxPath];
        } else {
            result = [NSString stringWithFormat:@"/"];
        }
        
        if ([self.item.file.mimeType hasPrefix:@"image/"]) {
            result = [result stringByAppendingFormat:@"Photos/"];
        }
    }
    return result;
}

//remote path could be directory or file
- (void) startLoadDropboxMetadata:(NSString *) remotePath {
    if (remotePath.length < 1) {
        remotePath = [self.item customValueForKey:kSHKDropboxDestinationDir];
        if (remotePath.length < 1) {
            remotePath = @"/";
        }
    }
    [self startLoadMetadataForPath:remotePath withHash:nil];
}

- (void) startLoadMetadataForPath:(NSString *)path withHash:(NSString *) remoteHash {
    DBRestClient *restClient = [self restClient];
    [restClient setDelegate:self];
    [DBRequest setNetworkRequestDelegate:self];
    if (remoteHash.length > 0) {
        [restClient loadMetadata:path withHash:remoteHash];
    } else {
        [restClient loadMetadata:path];
    }
    metadataStatus = _isStarting;
    [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
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
	[[[UIAlertView alloc] initWithTitle:@"Dropbox"
                                 message:SHKLocalizedString(@"Could not authenticate you. Please relogin.")
                                delegate:self
                       cancelButtonTitle:SHKLocalizedString(@"Cancel")
                       otherButtonTitles:SHKLocalizedString(@"Continue"), nil] show];
}

#pragma mark - DBRestClientDelegate methods

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

#pragma mark - DBRestClientDelegate methods - Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    if (!_startSending) {
        [[SHKActivityIndicator currentIndicator] hide];
    }
    if (metadata && metadata.path.length > 0) {
        if ([[metadata.path lastPathComponent] isEqualToDropboxPath:[self.item customValueForKey:kSHKDropboxStoredFileName]]) {
            if (![self shouldOverwrite]) {
                [self.item setCustomValue:metadata.rev forKey:kSHKDropboxParentRevision];
                [self showDropboxForm];
            } else {
                [self.item setCustomValue:metadata.rev forKey:kSHKDropboxParentRevision];
                [self startSendingStoredObject];
            }
        }
    }
    metadataStatus = _isChecked;
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {

    if (!_startSending) {
        [[SHKActivityIndicator currentIndicator] hide];
    }
    
    if ([error.domain isEqualToString:kDropboxErrorDomain] == YES && error.code == 404) {
        metadataStatus = _isChecked;
        [self startSendingStoredObject];
    } else {
        metadataStatus = _isNotChecked;
        [self checkDropboxAPIError:error];
    }
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
    if (buttonIndex != alertView.cancelButtonIndex) {
        [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
        [self performSelector:@selector(authorize) withObject:nil afterDelay:0.1]; //Avoid exception with animation conflicts between SDK and SHK UIs
	} else {
        [self SHKDropboxDidCansel];
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

#pragma mark - UI
// ask user to overwrite or duplicate file in Dropbox remote directory
- (void) showDropboxForm {
    
	SHKFormController *form = [[SHKCONFIG(SHKFormControllerSubclass) alloc] initWithStyle:UITableViewStyleGrouped title:SHKLocalizedString(@"Edit") rightButtonTitle:SHKLocalizedString(@"Continue")];
    
    NSArray *fileSecton = [NSArray arrayWithObjects:
                        [SHKFormFieldSettings label:SHKLocalizedString(@"File name")
                                                key:@"fileName"
                                               type:SHKFormFieldTypeTextNoCorrect
                                              start:[[self.item customValueForKey:kSHKDropboxDestinationDir] stringByAppendingString:[self.item customValueForKey:kSHKDropboxStoredFileName]]],
                        nil];
	[form addSection:fileSecton header:SHKLocalizedString(@"Do you want to overwrite existing file in %@?", [self sharerTitle]) footer:@"Tips: you could enter /folder_name/file_name to save the file in other folder or/with new name"];

	form.validateBlock = [self shareFormValidate];
	form.saveBlock = [self shareFormSave];
	form.cancelBlock = [self shareFormCancel];
	form.autoSelect = YES;
	
    self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:, self);
    [self pushViewController:form animated:NO];
    
	[[SHK currentHelper] showViewController:self];
}

- (FormControllerCallback)shareFormValidate {
    
    FormControllerCallback result = ^(SHKFormController *form) {
        
        NSString *formPath = [[form formValues] objectForKey:@"fileName"];
        if (formPath.length < 1 || [formPath isEqualToDropboxPath:@""] || [formPath isEqualToDropboxPath:@"/"]) {
            [[[UIAlertView alloc] initWithTitle:SHKCONFIG(appName)
                                         message:SHKLocalizedString(@"File name is wrong")
                                        delegate:self
                               cancelButtonTitle:SHKLocalizedString(@"Continue")
                               otherButtonTitles:nil,
               nil] show];
        } else {
            [form saveForm];
        }
    };
    return result;
}

- (FormControllerCallback)shareFormSave {
    
    FormControllerCallback result = ^(SHKFormController *form) {
        
        NSString *formPath = [[form formValues] objectForKey:@"fileName"];
        NSString *dir = [formPath stringByDeletingLastPathComponent];
        NSString *fileName = [formPath lastPathComponent];
        if (fileName.length > 0) {
            if (![fileName isEqualToString:kSHKDropboxStoredFileName]) {
                [self.item setCustomValue:fileName forKey:kSHKDropboxStoredFileName];
                [self.item setCustomValue:nil forKey:kSHKDropboxParentRevision];
            } else if (dir.length > 0) {
                [self.item setCustomValue:self.item.file.filename forKey:kSHKDropboxStoredFileName];
                [self.item setCustomValue:nil forKey:kSHKDropboxParentRevision];
            }
            
        }
        if (dir.length > 0) {
            NSString *remotePath = [self.item customValueForKey:kSHKDropboxDestinationDir];
            remotePath = [remotePath stringByAppendingPathComponent:dir];
            [self.item setCustomValue:remotePath forKey:kSHKDropboxDestinationDir];
        }
        [self startSendingStoredObject];
    };
    return result;
}

- (FormControllerCallback)shareFormCancel {
    
    FormControllerCallback result = ^(SHKFormController *form) {
        
        [self SHKDropboxDidCansel];
    };
    return result;
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
