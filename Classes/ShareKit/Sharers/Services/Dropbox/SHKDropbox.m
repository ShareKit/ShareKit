//
//  SHKDropbox.m
//  ShareKit
//
//  Valery Nikitin (submarine). Mistral LLC on 10/3/12.
//
//

#import "SHKDropbox.h"
#import "SHKConfiguration.h"
#import "SHKCustomFormControllerLargeTextField.h"
#import "SHKFormController.h"

#define kDropboxMaxFileSize 150000000
#define kSHKDropboxSizeChunks 104800 //TODO: move to configurator
#define kDropboxErrorDomain @"dropbox.com"

static NSString *const kSHKDropboxStoredItem=@"SHKDropboxStoredItem";
static NSString *const kSHKDropboxUserInfo =@"SHKDropboxUserInfo";
static NSString *const kSHKDropboxParentRevision =@"SHKDropboxParentRevision";
static NSString *const kSHKDropboxStoredFilePath =@"SHKDropboxFilePath";
static NSString *const kSHKDropboxDestinationDir =@"SHKDropboxDestinationDir";
static NSString *const kSHKDropboxStoredFileName =@"SHKDropboxStoredFileName";
static NSString *const kSHKDropboxUploadProgress =@"SHKDropboxUploadProgress";
static NSString *const kSHKDropboxImagePathExtention =@"png";
//static NSString *const kSHKDropboxLastRemotePath =@"SHKDropboxLastRemotePath";
//static NSString *const kSHKDropboxLastRemotePathHash =@"SHKDropboxLastRemotePathHash";
//static NSString *const kSHKDropboxStoredRemoteMetadata =@"SHKDropboxStoredRemoteMetadata";


typedef enum {
    _isNotChecked  =   0,
    _isStarting    =   1,
    _isChecked     =   2,
} SHKDropboxMetadata;


@interface SHKDropbox () {
    long long   __fileOffset;
    long long   __fileSize;
    NSString    *relinkUserId;
    NSString    *folderHash;
//    NSString    *remotePath;
    BOOL        _startSending;
    SHKDropboxMetadata metadataStatus;
}

@property (nonatomic, retain) DBRestClient *restClient;
+ (DBSession *) createNewDropbox;
+ (DBSession *) dropbox;
+ (NSString *)storedItemPath:(id)fileData;
+ (id) dataStoredForPath:(NSString *) filePath;
+ (NSInteger) fileSizeForImage:(UIImage *) image;
+ (long long) fileSizeForStoredFile:(NSString *) filePath;
+ (void) removeCachedFile:(NSString *)filePath;
- (void) showDropboxForm;
- (void) editFormValidate:(SHKFormController *) form;
- (void) editFormSave:(SHKFormController *) form;
- (void) editFormCancel:(SHKFormController *) form;
@end

@implementation SHKDropbox
@synthesize restClient = _restClient;
#pragma mark - Memory
- (void)dealloc
{
    [[self restClient] cancelAllRequests];
    [DBRequest setNetworkRequestDelegate:nil];
    _restClient.delegate = nil;
    [_restClient release];
    _restClient=nil;
    if (relinkUserId) {
        [relinkUserId release];
    }
    if (folderHash) {
        [folderHash release];
    }
//    if (remotePath) {
//        [remotePath release];
//    }
    if ([DBSession sharedSession].delegate == self) {
        [[DBSession sharedSession] setDelegate:nil];
    } else {
        [DBSession setSharedSession:nil];
    }
	[super dealloc];
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
        NSString *scheme = [[[[loadedPlist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
        if ([scheme isEqual:@"db-APP_KEY"])
        {
            errorMsg = @"Set your URL scheme correctly in ShareKit-Info.plist";
        }
    }
    if (errorMsg != nil)
    {
        [[[[UIAlertView alloc]
           initWithTitle:@"Error Configuring Session" message:errorMsg
           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
          autorelease]
         show];
    }
    //End reminder
    
//    http://stackoverflow.com/a/11261164/812678
    DBSession* session =[[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:[[root retain] autorelease]];
    session.delegate = nil; 
    [DBSession setSharedSession:session];
    [session release];
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
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

#pragma mark - Temporary file storeg (file or image)
+ (NSString *)storedItemPath:(id)fileData
{
    NSData *dataToSave = nil;
    if ([fileData isKindOfClass:[UIImage class]]) {
        dataToSave = UIImagePNGRepresentation((UIImage *) fileData);
    } else if ([fileData isKindOfClass:[NSData class]]) {
        dataToSave = fileData;
    } else {
        return nil;
    }
	NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!fileManager) {
        return nil;
    }
	NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
	NSString *cache = [paths objectAtIndex:0];
	NSString *localFilePath = [cache stringByAppendingPathComponent:@"Dropbox"];
	
	// Check if the path exists, otherwise create it
	if (![fileManager fileExistsAtPath:localFilePath])
		[fileManager createDirectoryAtPath:localFilePath withIntermediateDirectories:YES attributes:nil error:nil];
	
    NSString *uid = [NSString stringWithFormat:@"file-%.0f-%i", [[NSDate date] timeIntervalSince1970], arc4random()];
    if ([fileData isKindOfClass:[UIImage class]]) {
        uid = [uid stringByAppendingPathExtension:kSHKDropboxImagePathExtention];
    }
    localFilePath = [localFilePath stringByAppendingPathComponent:uid];
    [dataToSave writeToFile:localFilePath atomically:YES];
	return localFilePath;
}
+ (id) dataStoredForPath:(NSString *) filePath {

    if ([[filePath pathExtension] isEqualToString:kSHKDropboxImagePathExtention]) {
        return [UIImage imageWithContentsOfFile:filePath];
    } else {
        return [NSData dataWithContentsOfFile:filePath];
    }
}
+ (NSInteger) fileSizeForImage:(UIImage *) image {
    if (!image) {
        return -1;
    }
    return [UIImagePNGRepresentation(image) length];
}
+ (long long) fileSizeForStoredFile:(NSString *) filePath {
    if (filePath.length < 1) {
        return -1;
    }
	NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!fileManager) {
        return -1;
    }
	// Check if the path exists
	if (![fileManager fileExistsAtPath:filePath]) {
        return -1;
    } else {
        NSError *error = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        if ([attributes count] > 0 && !error) {
            return [[attributes objectForKey:NSFileSize] longLongValue];
        } else {
            return -1;
        }
    }
}
+ (void) removeCachedFile:(NSString *)filePath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
    if (!fileManager || filePath.length < 1) {
        return;
    }
    NSError *error = nil;
	if (![fileManager removeItemAtPath:filePath error:&error] || error) {
        SHKLog(@"<%@ : %p> Error remove file <%@> from cache. User info: %@, description %@", [self class], self, filePath, [error userInfo], [error localizedDescription]);
        return;
    }
}
#pragma mark - Handle URL

+ (BOOL) handleOpenURL:(NSURL *)url {
    SHKLog(@"handleOpenURL %@", url);
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        SHKDropbox *dropboxSharer = (SHKDropbox *)[DBSession sharedSession].delegate;
        if (!dropboxSharer || ![dropboxSharer isKindOfClass:[SHKDropbox class]]) {
            dropboxSharer = [[SHKDropbox alloc] init];
            DBSession *dropbox = [SHKDropbox dropbox];
            [dropbox setDelegate:dropboxSharer];
            [dropboxSharer autorelease];
        }
        [dropboxSharer performSelector:@selector(checkURL:) withObject:[[url retain] autorelease]];
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
        NSString *response = [NSString stringWithFormat:@"db-%@://%@/cancel", SHKCONFIG(dropboxAppKey), kDBDropboxAPIVersion];
        
        if ([[url absoluteString] isEqualToString:response]) {
            [[[[UIAlertView alloc]
               initWithTitle:@"Dropbox" message:SHKLocalizedString(@"Sorry, %@ encountered an error. Please try again.", [self sharerTitle])  delegate:self
               cancelButtonTitle:SHKLocalizedString(@"Cancel") otherButtonTitles:SHKLocalizedString(@"Continue"), nil]
              autorelease]
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
            [self performSelector:@selector(authorize) withObject:nil afterDelay:0.1]; //give a chance for previouse ViewController hide with animations
            return;
        }
        else
        {
            //start upload logic for pending share
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSDictionary *storedItem = [defaults objectForKey:kSHKDropboxStoredItem];
            if (storedItem)
            {
                self.item = [SHKItem itemFromDictionary:storedItem];
                NSString *storedPath = [self.item customValueForKey:kSHKDropboxStoredFilePath];
                if (storedPath.length > 0) {
                    if ([[storedPath pathExtension] isEqualToString:kSHKDropboxImagePathExtention]) {
                        self.item.image = [SHKDropbox dataStoredForPath:storedPath];
                    } else {
                        self.item.data = [SHKDropbox dataStoredForPath:storedPath];
                    }
                }
                [defaults removeObjectForKey:kSHKDropboxStoredItem];
            }
            [defaults synchronize];
            self.pendingAction = SHKPendingSend;
            
            [self authDidFinish:TRUE];
            
            if (self.item)
                [self tryPendingAction];
        }
    } else {
        [self authDidFinish:NO];
        [self performSelector:@selector(SHKDropboxDidCansel) withObject:nil afterDelay:0.5]; //give a chance for previouse ViewController hide with animations
    }
}
#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"Dropbox";
}

+ (BOOL)canShareURL
{
    return FALSE;
}

+ (BOOL)canShareImage
{
    return YES;
}

+ (BOOL)canShareText
{
    return FALSE;
}

+ (BOOL)canShareFile
{
    return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable
// TODO: version Bravo - forms to work with remote path
//- (BOOL)shouldAutoShare {
//    /*!
//     *  Currently we don't have enough information about remote folder content
//     *  and couldn't show to user the remote path and
//     *  possible collision with existing file.
//     *  So we return TRUE and start loading remote metadata.
//     *  We call startLoadDropboxMetadata before SHKSharer check reachability
//     *  just to make response better.
//     */
//    if (metadataStatus == _isNotChecked) {
//        [self performSelector:@selector(startLoadDropboxMetadata)];
//    }
//    metadataStatus = _isNotChecked;
//	return TRUE;
//}
- (BOOL) shouldOverwrite {
    return SHKCONFIG(dropboxShouldOverwrite);
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

        if (item.image)
        {
            [item setCustomValue:[SHKDropbox storedItemPath:item.image] forKey:kSHKDropboxStoredFilePath];
        }
        else if (item.data) {
            [item setCustomValue:[SHKDropbox storedItemPath:item.data] forKey:kSHKDropboxStoredFilePath];
        }
        
        NSMutableDictionary *itemRep = [NSMutableDictionary dictionaryWithDictionary:[self.item dictionaryRepresentation]];
        [[NSUserDefaults standardUserDefaults] setObject:itemRep forKey:kSHKDropboxStoredItem];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self retain]; // DBSession doesn't retain delegates
        [dropbox performSelector:@selector(linkFromController:) withObject:[[SHK currentHelper] rootViewForCustomUIDisplay] afterDelay:0.2]; //Avoid exeption with animation conflicts between SDK and SHK UIs
    }
}
+ (void)logout
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKDropboxStoredItem];
    [[SHKDropbox dropbox] unlinkAll];
}


#pragma mark - Before send


#pragma mark - Send

- (BOOL) send
{
    //hope image and data properties will be deprecated.
	if (![self validateItem])
		return NO;
    _startSending = FALSE;

    NSString *destinationDir = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKDropboxDestinationDir];
    if (destinationDir.length < 1) {

        if (![[DBSession sharedSession].root isEqualToDropboxPath:@"sandbox"]) {
            destinationDir = [[NSString stringWithFormat:@"/%@/", SHKCONFIG(appName)] normalizedDropboxPath];
        } else {
            destinationDir = [NSString stringWithFormat:@"/"];
        }
    }
    
    if ((item.shareType == SHKShareTypeFile && item.data)  || (item.shareType == SHKShareTypeImage && item.image))
    {
        if (![item customValueForKey:kSHKDropboxStoredFilePath]) {
            NSString *filename = nil;
            if (item.filename.length > 0) {
                filename = item.filename;
            } else if (item.title.length > 0){
                filename = item.title;
            } else {
                filename = [NSString stringWithFormat:@"ShareKit_Dropbox_file_%li", random() % 100];
            }
            NSString *filePath = nil;
            NSInteger fileSize = 0;
            if (item.image)
            {
                filePath = [SHKDropbox storedItemPath:item.image];
                fileSize = [SHKDropbox fileSizeForImage:item.image];
                if ([filename pathExtension].length < 1 ) {
                    filename = [filename stringByAppendingPathExtension:kSHKDropboxImagePathExtention];
                }
            } else if (item.data) {
                filePath = [SHKDropbox storedItemPath:item.data];
                fileSize = item.data.length;
            }
            if (fileSize > kDropboxMaxFileSize) {
                // TODO: version Bravo - check localization
                [self SHKDropboxDidFailWithError:[SHK error:SHKLocalizedString(@"File size exceed %@ limits", [self sharerTitle])]];
                return NO;
            }
            
            [item setCustomValue:filePath forKey:kSHKDropboxStoredFilePath];
            [item setCustomValue:destinationDir forKey:kSHKDropboxDestinationDir];
            [item setCustomValue:filename forKey:kSHKDropboxStoredFileName];            
        }
        
        metadataStatus = _isNotChecked;
        [self performSelectorOnMainThread:@selector(startLoadDropboxMetadata) withObject:destinationDir waitUntilDone:FALSE];
        
        [self retain];
		return TRUE;
    }
	
	return NO;
}

//remote path could be directory or file
- (void) startLoadDropboxMetadata:(NSString *) remotePath {
    if (remotePath.length < 1) {
        remotePath = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKDropboxDestinationDir];
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
}

//  https://www.dropbox.com/developers/start/files#ios
//  to get callback from DBRestClient you should use MainThread or
//  thread with runloop
- (void) startSendingStoredObject {

    DBRestClient *restClient = [self restClient];
    [restClient setDelegate:self];
    [DBRequest setNetworkRequestDelegate:self];

    NSString *localPath = [item customValueForKey:kSHKDropboxStoredFilePath];
    if (localPath.length < 1) {
        return;
    }
    NSString *destinationDir = [item customValueForKey:kSHKDropboxDestinationDir];
    if (destinationDir.length < 1) {
        destinationDir = @"/";
    }
    NSString *fileName = [item customValueForKey:kSHKDropboxStoredFileName];
    if (fileName.length < 1) {
        fileName = [localPath lastPathComponent];
    }
    if (fileName.length < 1) {
        return;
    }
    // Hope item.image & item.data will be deprecated
    NSInteger fileSize = [SHKDropbox fileSizeForStoredFile:localPath];
    if (fileSize < 0) {
        // TODO: version Bravo - check localization
        [self SHKDropboxDidFailWithError:[SHK error:@"File was removed before it was sending to Dropbox"]];
    }
    __fileOffset = 0;
    __fileSize = fileSize;
    _startSending = TRUE;
    NSString *parentRev = [item customValueForKey:kSHKDropboxParentRevision]; //nil in case of new file
    if (parentRev) {
        [[parentRev retain] autorelease];
    }
    if (fileSize <= kSHKDropboxSizeChunks) {
        [restClient uploadFile:[[fileName retain] autorelease]
                        toPath:[[destinationDir retain] autorelease]
                 withParentRev:parentRev
                      fromPath:[[localPath retain] autorelease]];
    } else {
        [restClient    uploadFileChunk:nil
                                offset:__fileOffset
                              fromPath:[[localPath retain] autorelease]];
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
	relinkUserId = [userId retain];
	[[[[UIAlertView alloc] initWithTitle:@"Dropbox"
                                 message:SHKLocalizedString(@"Could not authenticate you. Please relogin.")
                                delegate:self
                       cancelButtonTitle:SHKLocalizedString(@"Cancel")
                       otherButtonTitles:SHKLocalizedString(@"Continue"), nil] autorelease] show];
}

#pragma mark - DBRestClientDelegate methods

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
//    SHKLog(@"%@ %@ %@ uploaded %@", [client description], destPath, srcPath, [metadata description]);
    [SHKDropbox removeCachedFile:srcPath];
    [self sessionDidFinishWithUploadedFile:destPath fromUploadId:nil metadata:metadata];
}
- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress
           forFile:(NSString*)destPath from:(NSString*)srcPath {
    SHKLog(@"%@ %@ %@ upload progress = %.2f %", [client description], destPath,srcPath, progress * 100);
    [[NSNotificationCenter defaultCenter] postNotificationName:kSHKDropboxUploadProgress object:[NSNumber numberWithFloat:progress]];
}
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSString *srcPath = [[error userInfo] objectForKey:@"sourcePath"];
    [SHKDropbox removeCachedFile:srcPath];
    [self SHKDropboxDidFailWithError:error];
}
- (void)restClient:(DBRestClient *)client uploadedFileChunk:(NSString *)uploadId newOffset:(unsigned long long)offset
          fromFile:(NSString *)localPath expires:(NSDate *)expiresDate {
    __fileOffset = offset;
    if (__fileOffset < __fileSize) {
        [client uploadFileChunk:uploadId offset:__fileOffset fromPath:localPath];
    } else {
        NSString *fileName = [item customValueForKey:kSHKDropboxStoredFileName];
        if (fileName.length < 1) {
            fileName = [NSString stringWithFormat:@"ShareKit-file-%lu", random() % 200];
        }
        NSString *destinationDir = [item customValueForKey:kSHKDropboxDestinationDir];
        [item setCustomValue:localPath forKey:uploadId];
        if (destinationDir.length < 1) {
            destinationDir = @"/";
        }
        NSString *parentRev = [item customValueForKey:kSHKDropboxParentRevision];
        [client uploadFile:fileName toPath:destinationDir withParentRev:parentRev fromUploadId:uploadId];
        __fileOffset = 0;
        __fileSize = 0;
    }
}
- (void)restClient:(DBRestClient *)client uploadFileChunkFailedWithError:(NSError *)error {
    NSString *srcPath = [[error userInfo] objectForKey:@"sourcePath"];
    [SHKDropbox removeCachedFile:srcPath];    
    [self SHKDropboxDidFailWithError:error];
}
- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath fromUploadId:(NSString *)uploadId
          metadata:(DBMetadata *)metadata {
    NSString *srcPath = [self.item customValueForKey:uploadId];
    [SHKDropbox removeCachedFile:srcPath];
    [self sessionDidFinishWithUploadedFile:destPath fromUploadId:uploadId metadata:metadata];
}
- (void)restClient:(DBRestClient *)client uploadFromUploadIdFailedWithError:(NSError *)error {
    NSString *srcPath = [[error userInfo] objectForKey:@"sourcePath"];
    [SHKDropbox removeCachedFile:srcPath];
    [self SHKDropboxDidFailWithError:error];
}

// TODO: version Bravo - methods below
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata {
    SHKLog(@"DBRestClient <%@ %@>\n%@", client, [client description], metadata);
    if (metadata.hash.length > 0) {
        if (folderHash.length > 0 && ![metadata.hash isEqualToString:[NSString stringWithFormat:@"%@", folderHash]]) {
            [folderHash release];
            folderHash = nil;
            folderHash = [metadata hash];
            [self serializeRemoteMetadata:[[metadata retain] autorelease]];            
        } else if (folderHash.length < 1) {
            folderHash = [metadata hash];
            [self serializeRemoteMetadata:[[metadata retain] autorelease]];
        }
    } 
    metadataStatus = _isChecked;
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path {
    SHKLog(@"DBRestClient <%@ %@>\n%@", client, [client description], path);
    metadataStatus = _isChecked;
}
- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error {
    SHKLog(@"restClient:loadMetadataFailedWithError: %@", [error localizedDescription]);
    metadataStatus = _isNotChecked;
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods 
- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (relinkUserId) {
            [[DBSession sharedSession] linkUserId:relinkUserId  fromController:[[SHK currentHelper] rootViewForCustomUIDisplay]];
        } else {
            [[DBSession sharedSession] linkFromController:[[SHK currentHelper] rootViewForCustomUIDisplay]];
        }
	}
    if (relinkUserId) {
        [relinkUserId release];
    }
	relinkUserId = nil;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	if (index != alertView.cancelButtonIndex) {
        if (relinkUserId) {
            [[DBSession sharedSession] linkUserId:relinkUserId  fromController:[[SHK currentHelper] rootViewForCustomUIDisplay]];
        } else {
            [[DBSession sharedSession] linkFromController:[[SHK currentHelper] rootViewForCustomUIDisplay]];
        }
	}
    if (relinkUserId) {
        [relinkUserId release];
    }
	relinkUserId = nil;
}

#pragma mark - Delegate Notifications
- (void) SHKDropboxDidFailWithError:(NSError *) error {
    _startSending = FALSE;
    
    //  Check 401 - Bad or expired token. This can happen if the user or Dropbox
    //  revoked or expired an access token.
    NSInteger dbErrorCode = error.code;
    if (error.domain == kDropboxErrorDomain && dbErrorCode == 401) {
        [[SHKDropbox dropbox] unlinkAll];
        [[[[UIAlertView alloc] initWithTitle:[self sharerTitle]
                                     message:SHKLocalizedString(@"Could not authenticate you. Please relogin.")
                                    delegate:self
                           cancelButtonTitle:SHKLocalizedString(@"Cancel")
                           otherButtonTitles:SHKLocalizedString(@"Continue"), nil] autorelease] show];
    } else {
        NSError *internal = nil;
        if (dbErrorCode == 507) {
            internal = [SHK error:SHKLocalizedString(@"You are over Dropbox storage quota")];
        }
        if (dbErrorCode >= 500 && dbErrorCode < 600 && dbErrorCode != 507) {
            internal = [SHK error:SHKLocalizedString(@"Sorry, %@ encountered an error. Please try again.", [self sharerTitle])];
        }
        if (dbErrorCode == 400) {
            internal = [SHK error:SHKLocalizedString(@"The file extension %@ is on Dropbox's ignore list", [item.filename pathExtension])];
        }
        [self sendDidFailWithError:internal];
        [self stopNetworkIndication];        
        [self release]; //see [self send]
    }
}

- (void) SHKDropboxDidFinishSuccess {
    _startSending = FALSE;
    [self sendDidFinish];
    [self stopNetworkIndication];
    [self release];
}

- (void) SHKDropboxDidCansel {
    _startSending = FALSE;
    [self sendDidCancel];
    [self stopNetworkIndication];
    [self release];
}
- (void) stopNetworkIndication {
    outstandingRequests = 0;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
#pragma mark - Check Overwrite
//  - replace/duplicate file in Dropbox remote directory
- (void) sessionDidFinishWithUploadedFile:(NSString *)destPath fromUploadId:(NSString *)uploadId
metadata:(DBMetadata *)metadata {
    
    if (metadata && destPath.length > 0 && metadata.path.length > 0) {
        if (![destPath isEqualToDropboxPath:metadata.path]) {
            if (![self shouldOverwrite]) {
                [self showDropboxForm];
            } else {
                [self restClient] 
            }
        } else {
            [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil];
        }
    } else {
        [self performSelector:@selector(SHKDropboxDidFinishSuccess) withObject:nil];
    }
}

#pragma mark - UI
- (void) showDropboxForm {
    
	SHKFormController *form = [[SHKCONFIG(SHKFormControllerSubclass) alloc] initWithStyle:UITableViewStyleGrouped title:SHKLocalizedString(@"Edit") rightButtonTitle:SHKLocalizedString(@"Done")];
    
    NSArray *fileSecton = [NSArray arrayWithObjects:
                        [SHKFormFieldSettings label:SHKLocalizedString(@"File name")
                                                key:@"name"
                                               type:SHKFormFieldTypeTextNoCorrect
                                              start:item.filename],
                           [SHKFormFieldSettings label:[NSString stringWithFormat:@"%@ %@", [self sharerTitle],SHKLocalizedString(@"path")]
                                               key:@"path"
                                              type:SHKFormFieldTypeTextNoCorrect
                                             start:remotePath],
                        nil];
//TODO:  SHKLocalizedString
	[form addSection:fileSecton header:@"You have file with same name in Dropbox:" footer:nil];
	form.delegate = self;
	form.validateSelector = @selector(editFormValidate:);
	form.saveSelector = @selector(editFormSave:);
	form.cancelSelector = @selector(editFormCancel:);
	form.autoSelect = YES;
	
    self.navigationBar.tintColor = SHKCONFIG_WITH_ARGUMENT(barTintForView:, self);
    [self pushViewController:form animated:NO];
    [form release];
    
	[[SHK currentHelper] showViewController:self];
}

- (void) editFormValidate:(SHKFormController *) form {
    
}
- (void) editFormSave:(SHKFormController *) form {
    
}

- (void) editFormCancel:(SHKFormController *) form {
    
}


//#pragma mark - Helpers
//- (void) serializeRemoteMetadata:(DBMetadata *) metadata {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSString *archivePath = [defaults objectForKey:kSHKDropboxStoredRemoteMetadata];
//    if (archivePath.length > 0) {
//        NSFileManager *fileManager = [NSFileManager defaultManager];
//        [fileManager removeItemAtPath:archivePath error:nil];
//    }
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
//    NSString *cache = [paths objectAtIndex:0];
//    NSString *localFilePath = [cache stringByAppendingPathComponent:@"Dropbox"];
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    if (![fileManager fileExistsAtPath:localFilePath]) {
//        [fileManager createDirectoryAtPath:localFilePath withIntermediateDirectories:YES attributes:nil error:nil];
//    }
//    NSString *hash = nil;
//    if (metadata.hash.length > 0) {
//        archivePath = [localFilePath stringByAppendingPathComponent:metadata.hash];
//        hash = metadata.hash;
//    } else {
//        archivePath = [localFilePath stringByAppendingPathComponent:@"metadata"];
//        hash = @"metadata";
//    }
//    
//    NSMutableArray *remoteContent = [NSMutableArray arrayWithCapacity:[metadata.contents count]];
//    for (DBMetadata* child in metadata.contents) {
//        if (child.path.length > 0) {
//            [remoteContent addObject:[NSDictionary dictionaryWithObjectsAndKeys:child.path, @"path", [NSNumber numberWithBool:child.isDirectory], @"flag", nil]];
//        }
//    }
//    if (remoteContent.count > 0) {
//        NSMutableData *data = [NSMutableData data];
//        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
//        [archiver encodeObject:remoteContent forKey:hash];
//        [archiver finishEncoding];
//        BOOL result = [data writeToFile:archivePath atomically:YES];
//
//        if (!result) {
//            [defaults removeObjectForKey:kSHKDropboxStoredRemoteMetadata];
//            [defaults removeObjectForKey:kSHKDropboxLastRemotePathHash];
//        } else {
//            [defaults setObject:archivePath forKey:kSHKDropboxStoredRemoteMetadata];
//            [defaults setObject:hash forKey:kSHKDropboxLastRemotePathHash];
//        }
//        data = nil;
//        [archiver release];
//        archiver = nil;        
//    }
//    [defaults synchronize];
//}
//
//- (NSArray *) remoteContentFromStoredMetadata {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSString *archivePath = [defaults objectForKey:kSHKDropboxStoredRemoteMetadata];
//    NSString *hash = [defaults objectForKey:kSHKDropboxLastRemotePathHash];
//    if (hash.length < 1 || archivePath.length < 1) {
//        return nil;
//    }
//    NSData *data = [NSData dataWithContentsOfFile:archivePath];
//    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
//    NSArray *result = [unarchiver decodeObjectForKey:hash];
//    [unarchiver finishDecoding];
//    [unarchiver release];
//    unarchiver = nil;
//    data = nil;
//    return result;
//}

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
