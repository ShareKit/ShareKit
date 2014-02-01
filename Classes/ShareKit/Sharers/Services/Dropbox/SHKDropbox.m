//
//  SHKDropbox.m
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKDropbox.h"
#import "SharersCommonHeaders.h"
#import "SHKUploadInfo.h"

///Where user starts to browse the save location
#define kSHKDropboxStartDirectory @"/"

#define kDropboxMaxFileSize 150000000
#define kSHKDropboxSizeChunks 2097152 //this is the default size of Dropbox ios sdk made chunks.
#define kDropboxErrorDomain @"dropbox.com"
#define kDropboxDomain @"www.dropbox.com"
#define kDropboxResourseDomain  @"dl.dropbox.com"

static NSString *const kSHKDropboxUserInfo =@"SHKDropboxUserInfo";
static NSString *const kSHKDropboxParentRevision =@"SHKDropboxParentRevision";
static NSString *const kSHKDropboxStoredFileName =@"SHKDropboxStoredFileName";
static NSString *const kSHKDropboxDestinationDirKeyName = @"kSHKDropboxDestinationDirKeyName";

@interface SHKDropbox () {
    long long   __fileOffset;
    long long   __fileSize;
}

@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) UIAlertView *overwriteAlert;
@property (nonatomic) BOOL fileOverwriteChecked;
@property BOOL chunkedUploadFailReportedAlready;

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
        _restClient = client;
        _restClient.delegate = self;
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
#pragma mark Authentication

- (BOOL)isAuthorized
{
    return [[SHKDropbox dropbox] isLinked];
}

- (void)promptAuthorization
{
    if (![[SHKDropbox dropbox] isLinked]) {
        
        DBSession *dropbox = [SHKDropbox dropbox];
        if (dropbox.delegate) {//we do not set delegate. Probably some other, foreign session exists with different delegate. We create our own session. Not sure if this can happen though.
            dropbox = [SHKDropbox createNewDropbox];
        }

        [DBRequest setNetworkRequestDelegate:self];
        
        [self saveItemForLater:SHKPendingShare];
        
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
    
    DBSession *dropbox = [SHKDropbox dropbox];
    SHKDropbox *dropboxSharer = [[[self class] alloc] init];

    if ([dropbox handleOpenURL:url]) {
        [dropboxSharer checkURL:url];
        return TRUE;
    } else {
        return FALSE;
    }
}

// Just to keep watch dog out
- (void) checkURL:(NSURL *)url {
    
    if ([[DBSession sharedSession] isLinked])
    {
        //  check url
        //  if user has pressed "Cancel" in dialogue, url = "db-APP-KEY://API_VERSION/cancel"
        
        if ([[url absoluteString] rangeOfString:@"cancel"].length > 0 && [[url absoluteString] rangeOfString:[NSString stringWithFormat:@"db-%@", SHKCONFIG(dropboxAppKey)]].length > 0) {
            
            [self authDidFinish:NO];
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
                [self performSelector:@selector(tryPendingAction) withObject:nil afterDelay:0.7]; //Let Oauth login view dismiss
        }
    } else {
        
        [self authDidFinish:NO];
    }
}

#pragma mark - UI

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
    
    if (type == SHKShareTypeUserInfo) return nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (type == SHKShareTypeFile && [self.item customValueForKey:kSHKDropboxDestinationDir]) return nil;
#pragma clang diagnostic pop
    if (type == SHKShareTypeFile && self.item.dropboxDestinationDirectory) return nil; //if destination dir is prefilled, do not let user choose
    
    NSString *startDir = kSHKDropboxStartDirectory;
    SHKFormFieldOptionPickerSettings *directoryField = [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Path")
                                                                                           key:kSHKDropboxDestinationDirKeyName
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
    [self displayActivity:SHKLocalizedString(@"Loading...")];
    
    if (optionController.selectionValue) {
        [self.restClient loadMetadata:optionController.selectionValue];
    } else {
        [self.restClient loadMetadata:optionController.settings.start];
    }
    [[SHK currentHelper] keepSharerReference:self];
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController *)optionController {
    
    [self hideActivityIndicator];
    //TODO: cancel metadata load (directory browse) request. Dropbox SDK allows only to cancel all requests. It can happen, that there are more requests, possibly uploads, in progress and we do not want to stop these. Implement this, after Dropbox SDK exposes running requests.
}

#pragma mark - Share form validation (check metadata - if file exists on Dropbox)

- (FormControllerCallback)shareFormValidate {
    
    __weak typeof(self) weakSelf = self;
    
    FormControllerCallback result =  ^(SHKFormController *form) {
        
        weakSelf.pendingForm = form;
        NSDictionary *formValues = [form formValues];
        NSString *destinationDir = [formValues objectForKey:kSHKDropboxDestinationDirKeyName];
        
        [weakSelf checkFileOverwriteDestinationDir:destinationDir];
    };
    return result;
}

- (void)checkFileOverwriteDestinationDir:(NSString *)destinationDir {
    
    // Display an activity indicator
    [self displayActivity:SHKLocalizedString(@"Connecting...")];
    
    NSString *dropboxFileName = [self.item.file.filename normalizedDropboxPath];
    [self.item setCustomValue:dropboxFileName forKey:kSHKDropboxStoredFileName];
    
    if (![destinationDir hasSuffix:@"/"]) {
        destinationDir = [destinationDir stringByAppendingString:@"/"];
    }
    
    NSString *remoteFilePath = [destinationDir stringByAppendingString:dropboxFileName];
    [self startLoadMetadataForPath:remoteFilePath withHash:nil];
}

//TODO: is this method needed? We can call restClient directly...
- (void) startLoadMetadataForPath:(NSString *)path withHash:(NSString *) remoteHash {
    
    DBRestClient *restClient = [self restClient];
    [restClient setDelegate:self];
    [DBRequest setNetworkRequestDelegate:self];
    [[SHK currentHelper] keepSharerReference:self];
    if (remoteHash.length > 0) {
        [restClient loadMetadata:path withHash:remoteHash];
    } else {
        [restClient loadMetadata:path];
    }
}

#pragma mark - DBRestClientDelegate methods (Metadata)

- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    
    [self hideActivityIndicator];
    
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
            [[SHK currentHelper] removeSharerReference:self];
            return;
        }
        
        if ([[metadata.path lastPathComponent] isEqualToDropboxPath:[self.item customValueForKey:kSHKDropboxStoredFileName]]) { //form validation detected file exists (or existed) on Dropbox
            
            [self.item setCustomValue:metadata.rev forKey:kSHKDropboxParentRevision];
            
            if ([SHKCONFIG(dropboxShouldOverwriteExistedFile) boolValue] || metadata.isDeleted) {
                
                [self startSharing];
                [[SHK currentHelper] removeSharerReference:self];
                
            } else {
                
                self.overwriteAlert = [[UIAlertView alloc] initWithTitle:[[self class] sharerTitle]
                                           message:SHKLocalizedString(@"Do you want to overwrite existing file in %@?", [[self class] sharerTitle])
                                          delegate:self
                                 cancelButtonTitle:SHKLocalizedString(@"Cancel")
                                 otherButtonTitles:@"OK", nil];
                [self.overwriteAlert show];
                //sharer reference will be removed in alert delegate method
            }
        }
        
    } else {
        
        [[SHK currentHelper] removeSharerReference:self];
    }
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {

    [self hideActivityIndicator];
    
    if ([error.domain isEqualToString:kDropboxErrorDomain] == YES && error.code == 404) {
        [self startSharing];
    } else {
        [self checkDropboxAPIError:error];
    }
    [[SHK currentHelper] removeSharerReference:self];
}

#pragma mark - Send

- (BOOL)send
{
	if (self.item.shareType == SHKShareTypeImage) {
        
        [self.item convertImageShareToFileShareOfType:SHKImageConversionTypePNG quality:0];
    }
    
    if (![self validateItem]) return NO;

    if (self.item.shareType == SHKShareTypeFile) {
        
        if (self.fileOverwriteChecked) {//is checked during form validation. Might be NO, if destination dir was supplied, thus no form was showed.
            
            [self startSendingStoredObject];
            
        } else {
            
            NSString *destinationDir;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            if ([self.item customValueForKey:kSHKDropboxDestinationDir]) {
                destinationDir = [self.item customValueForKey:kSHKDropboxDestinationDir];
#pragma clang diagnostic pop
            } else if (self.item.dropboxDestinationDirectory) {
                destinationDir = self.item.dropboxDestinationDirectory;
            } else {
                destinationDir = kSHKDropboxStartDirectory;
            }
            [self.item setCustomValue:destinationDir forKey:kSHKDropboxDestinationDirKeyName];
            [self checkFileOverwriteDestinationDir:destinationDir];
        }
        
    } else if (self.item.shareType == SHKShareTypeUserInfo) {
        
        self.quiet = YES;
        [self.restClient loadAccountInfo];
        [[SHK currentHelper] keepSharerReference:self];
        [self sendDidStart];
		return TRUE;
    }
	
	return NO;
}

- (void)cancel {
    
    NSMutableSet *requests = [self.restClient valueForKey:@"requests"];
    for (DBRequest *request in requests) {
        if ([[request.sourcePath lastPathComponent] isEqualToString:self.item.file.filename]) {
            [request cancel];
            break;
        }
    }
    [self sendDidCancel];
    [[SHK currentHelper] removeSharerReference:self];
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

- (void)startSharing {
    
    if (self.pendingForm) {
        self.fileOverwriteChecked = YES;
        [self.pendingForm saveForm]; //start sharing
    } else {
        [self startSendingStoredObject]; //if there was prefilled kSHKDropboxDestinationDir. NO UI picker is presented to the user in this case.
    }
}

//  https://www.dropbox.com/developers/start/files#ios
//  to get callback from DBRestClient you should use MainThread or
//  thread with runloop
- (void) startSendingStoredObject {
    
    [self sendDidStart];

    DBRestClient *restClient = [self restClient];
    [restClient setDelegate:self];
    [DBRequest setNetworkRequestDelegate:self];

    NSString *localPath = self.item.file.path;
    if (localPath.length < 1) {
        return;
    }
    NSString *destinationDir = [self.item customValueForKey:kSHKDropboxDestinationDirKeyName];
    NSAssert([destinationDir length] > 0, @"empty destination directory!");
    NSString *fileName = [self.item customValueForKey:kSHKDropboxStoredFileName];
    if (fileName.length < 1) {
        fileName = [localPath lastPathComponent];
    }
    if (fileName.length < 1) {
        return;
    }

    NSInteger fileSize = self.item.file.size;
    if (fileSize < 0) {
        [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was an error while sharing")]];
    }
    __fileOffset = 0;
    __fileSize = fileSize;
    
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
    
    [[SHK currentHelper] keepSharerReference:self];
}

#pragma mark -  DBNetworkRequestDelegate methods

static int outstandingRequests = 0;

- (void)networkRequestStarted {
    // Notify that we started
	outstandingRequests++;
	if (outstandingRequests == 1) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	}
}
- (void)networkRequestStopped {
	outstandingRequests--;
	if (outstandingRequests <= 0) {
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

#pragma mark - DBRestClientDelegate methods (simple upload)

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
//    SHKLog(@"%@ %@ %@ uploaded %@", [client description], destPath, srcPath, [metadata description]);
    [self SHKDropboxGetSharableLink:destPath];
//    [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.01];
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    //SHKLog(@"%@ %@ %@ upload progress = %.2f %", [client description], destPath,srcPath, progress);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxUploadProgress object:[NSNumber numberWithFloat:progress]];
#pragma clang diagnostic pop
    [self showProgress:progress];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {

    [self performSelector:@selector(checkDropboxAPIError:) withObject:error afterDelay:0.01];
}

#pragma mark - DBRestClientDelegate methods (chunked upload) 

- (void)restClient:(DBRestClient *)client uploadedFileChunk:(NSString *)uploadId newOffset:(unsigned long long)offset
          fromFile:(NSString *)localPath expires:(NSDate *)expiresDate {
    
    //SHKLog(@"%@ new offset %.2llu progress %llu", [client description], offset, offset/__fileSize);
    __fileOffset = offset;
    if (__fileOffset < __fileSize) {
        [client uploadFileChunk:uploadId offset:__fileOffset fromPath:localPath];
    } else {
        NSString *fileName = [self.item customValueForKey:kSHKDropboxStoredFileName];
        if (fileName.length < 1) {
            fileName = [NSString stringWithFormat:@"ShareKit-file-%lu", random() % 200];
        }
        NSString *destinationDir = [self.item customValueForKey:kSHKDropboxDestinationDirKeyName];
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

- (void)restClient:(DBRestClient *)client uploadFileChunkProgress:(CGFloat)progress
           forFile:(NSString *)uploadId offset:(unsigned long long)offset fromPath:(NSString *)localPath {
    
    unsigned long long chunkUploadedBytes = kSHKDropboxSizeChunks * progress;
    unsigned long long totalUploadedBytes = chunkUploadedBytes + offset;
    float totalProgress = (float)totalUploadedBytes/__fileSize;
    //SHKLog(@"%@ upload chunk progress = %.2f %", [client description], progress);
    [self showProgress:totalProgress];
}

- (void)restClient:(DBRestClient *)client uploadFileChunkFailedWithError:(NSError *)error {
   
    //this method is called more than once (a bug in the sdk?). Error checking should happen only once.
    if (!self.chunkedUploadFailReportedAlready) {
        
        //must be delayed, otherwise premature sharer's dealloc.
        [self performSelector:@selector(checkDropboxAPIError:) withObject:error afterDelay:0.1];
        self.chunkedUploadFailReportedAlready = YES;
    }
}

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath fromUploadId:(NSString *)uploadId
          metadata:(DBMetadata *)metadata {

//    [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil afterDelay:0.01];
    [self SHKDropboxGetSharableLink:destPath];
}

- (void)restClient:(DBRestClient *)client uploadFromUploadIdFailedWithError:(NSError *)error {

    [self performSelector:@selector(checkDropboxAPIError:) withObject:error afterDelay:0.01];
}

#pragma mark - DBRestClientDelegate methods (SharableLink)

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link
           forFile:(NSString*)path {
    
    if ([link rangeOfString:kDropboxDomain].length > 0) {
        link = [link stringByReplacingOccurrencesOfString:kDropboxDomain withString:kDropboxResourseDomain];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxSharableLink object:link];
#pragma clang diagnostic pop
    [self performSelector:@selector(SHKDropboxDidFinishSuccessWithResponse:) withObject:@{SHKShareResponseKeyName:link} afterDelay:0.2];
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxSharableLink object:error];
#pragma clang diagnostic pop
    [self performSelector:@selector(SHKDropboxDidFinishSuccessWithResponse:) withObject:@{SHKShareResponseKeyName:error} afterDelay:0.2];
}

#pragma mark - Check API Error
- (void) checkDropboxAPIError:(NSError *) error {
    
    [[SHK currentHelper] removeSharerReference:self]; //see [self send]
    
    //  Check 401 - Bad or expired token. This can happen if the user or Dropbox
    //  revoked or expired an access token.
    NSInteger dbErrorCode = error.code;
    if ([error.domain isEqual: kDropboxErrorDomain] == YES && (dbErrorCode == 401 || dbErrorCode == 403)) {
        
        [[SHKDropbox dropbox] unlinkAll];
        
        if ([self.item customValueForKey:kSHKDropboxDestinationDirKeyName]) {//user already picked the path
            
            [self saveItemForLater:SHKPendingSend];
            [self shouldReloginWithPendingAction:SHKPendingSend];
            
        } else {
            
            [self saveItemForLater:SHKPendingShare];
            [self shouldReloginWithPendingAction:SHKPendingShare];
        }

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
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if ([alertView isEqual:self.overwriteAlert]) {
        
        if (buttonIndex == alertView.cancelButtonIndex) {
            [[self pendingForm] cancel];
        } else {
            self.fileOverwriteChecked = YES;
            [self startSharing];
        }
        [[SHK currentHelper] removeSharerReference:self];
    }
}

#pragma mark - Delegate Notifications

- (void)SHKDropboxDidFinishSuccessWithResponse:(NSDictionary *)response {

    [self sendDidFinishWithResponse:response];
    [self stopNetworkIndication];
    [[SHK currentHelper] removeSharerReference:self];
}

- (void) stopNetworkIndication {
    outstandingRequests = 0;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) SHKDropboxGetSharableLink:(NSString *) remotePath {
    if (remotePath.length < 1) {
        [self performSelector:@selector(SHKDropboxDidFinishSuccessWithResponse:) withObject:nil afterDelay:0.1];
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
