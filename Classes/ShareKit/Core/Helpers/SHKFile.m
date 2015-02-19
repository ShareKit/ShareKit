//
//  SHKFile.m
//  ShareKit
//
//  Created by Jacob Dunn on 3/5/13.
//
//

#import "SHKFile.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "Debug.h"

@interface SHKFile()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic) NSUInteger size;
@property (nonatomic) NSUInteger duration;
@property (nonatomic, strong) NSString *temporaryUIDocumentsInteractionControllerCopyPath;

@end

static NSString *tempDirectory;

@implementation SHKFile

#pragma mark ---
#pragma mark initialization

//TODO: change to URL, avoid static

+(void)initialize
{
    // Create our temp directory, if it doesn't exist
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    tempDirectory = [cachesDirectory stringByAppendingString:@"/com.shk.temp/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

-(void)dealloc
{
    [self removeTempFile];
}

- (id)initWithFilePath:(NSString *)path {
    
    self = [super init];
    
    if (self) {
        
        _path = path;
        _filename = path.lastPathComponent;
        _mimeType = [self MIMETypeForPath:_filename];
        _UTIType = [self NSStringUTITypeForPath:_filename];
    }
    return self;
}

- (id)initWithFileData:(NSData *)data filename:(NSString *)filename {
    
    self = [super init];
    
    if (self) {
        
        _data = data;
        
        if (!filename) filename = [NSString stringWithFormat:@"ShareKit_file_%li", random() % 100];
        
        _filename = filename;
        _mimeType = [self MIMETypeForPath:filename];
        _UTIType = [self NSStringUTITypeForPath:filename];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {

    self = [super init];
    
    if (self) {
        
        _path = [decoder decodeObjectForKey:kSHKFilePath];
        
        if (_path) {
            
            _filename = _path.lastPathComponent;
            _mimeType = [self MIMETypeForPath:_filename];
            _UTIType = [self NSStringUTITypeForPath:_filename];
        
        } else {
            
            _data = [decoder decodeObjectForKey:kSHKFileData];
            _filename = [decoder decodeObjectForKey:kSHKFileName];
            _mimeType = [self MIMETypeForPath:_filename];
            _UTIType = [self NSStringUTITypeForPath:_filename];
        }
    }
    return self;
}

#pragma mark ---
#pragma mark NSCoding

static NSString *kSHKFilePath = @"kSHKFilePath";
static NSString *kSHKFileName = @"kSHKFileName";
static NSString *kSHKFileData = @"kSHKFileData";

-(void)encodeWithCoder:(NSCoder *)encoder
{
    if ([self hasPath]) {
        [encoder encodeObject:self.path forKey:kSHKFilePath];
    } else {
        [encoder encodeObject:self.filename forKey:kSHKFileName];
        [encoder encodeObject:self.data forKey:kSHKFileData];
    }
}

#pragma mark ---
#pragma mark Getters


-(BOOL)hasPath
{
    return _path != nil;
}

-(BOOL)hasData
{
    return _data != nil;
}

-(NSString *)path
{
    if(_path == nil) [self createPathFromData];
    return _path;
}

-(NSData *)data
{
    if(_data == nil) [self createDataFromPath];
    return _data;
}

-(NSUInteger)size
{
    if(_size == 0) [self getSize];
    return _size;
}

-(NSUInteger)duration
{
    if(_duration == 0) [self getDuration];
    return _duration;
}

#pragma mark ---
#pragma mark Data / Path Methods

-(void)createPathFromData
{
    SHKLog(@"Warning, you are saving a file to the disc");
    NSString *sanitizedFileName = [self sanitizeFileNameString:self.filename];
    
    // Our filename
    _path = [tempDirectory stringByAppendingPathComponent:sanitizedFileName];
    
    // Create our file
    if([[NSFileManager defaultManager] fileExistsAtPath:_path]){
        
        // TODO: This file already exists - throw an error
        
        //SHKLog(@"file already exists, OK?");
        //return;
        //NSAssert(NO, @"file already exists?!");
    }
    
    // Read our file into the file system
    [_data writeToFile:_path atomically:YES];
}

- (NSString *)sanitizeFileNameString:(NSString *)fileName {
    
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    NSString *result = [[fileName componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
    return result;
}


-(void)createDataFromPath
{
    SHKLog(@"Warning, you are reading file to memory");
    NSError *error;
    _data = [NSData dataWithContentsOfFile:_path options:NSDataReadingMapped|NSDataReadingUncached error:&error];
    
    if(error){
        // TODO: Handle this error
    }
}

-(void)removeTempFile
{
    if(!self.hasPath || [self.path rangeOfString:tempDirectory].location == NSNotFound) return;
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
}

- (NSURL *)URL {
    
    NSURL *result = [[NSURL alloc] initFileURLWithPath:[self.path stringByExpandingTildeInPath]];
    return result;
}

#pragma mark ---
#pragma mark Size

-(void)getSize
{
    _size = (self.hasData)
    ? self.data.length
    : [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil][NSFileSize] unsignedIntegerValue];
}

#pragma mark ---
#pragma mark Duration

-(void)getDuration
{
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:self.path] options:options];
    _duration = CMTimeGetSeconds(asset.duration);
}

#pragma mark ---
#pragma mark Utility

- (NSString *)MIMETypeForPath:(NSString *)path{
    
    NSString *result = @"";
    CFStringRef uti = CreateUTITypeForPath(path);
    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    return result;
}

CFStringRef CreateUTITypeForPath(NSString *path) {
    
    NSString *extension = [path pathExtension];
    CFStringRef result = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    return result;
}

- (NSString *)NSStringUTITypeForPath:(NSString *)path {
    
    NSString *result = nil;
    CFStringRef uti = CreateUTITypeForPath(path);
    if (uti) {
        result = CFBridgingRelease(uti);
    }
    return result;
}

#pragma mark UIDocumentInteractionController helpers

- (NSString *)makeTemporaryUIDICCopyWithFileExtension:(NSString *)extension {
    
    NSString *fileName = [@"tempCopy." stringByAppendingString:extension];
    self.temporaryUIDocumentsInteractionControllerCopyPath = [tempDirectory stringByAppendingPathComponent:fileName];
    
    //clear previous
    [[NSFileManager defaultManager] removeItemAtPath:self.temporaryUIDocumentsInteractionControllerCopyPath error:nil];
    
    NSError *error;
    BOOL success;
    if (self.hasData) {
        success = [self.data writeToFile:self.temporaryUIDocumentsInteractionControllerCopyPath atomically:YES];
    } else {
        [[NSFileManager defaultManager] copyItemAtPath:self.path toPath:self.temporaryUIDocumentsInteractionControllerCopyPath error:&error];
        success = error == nil;
    }
    
    if (!success) self.temporaryUIDocumentsInteractionControllerCopyPath = nil;
    
    return self.temporaryUIDocumentsInteractionControllerCopyPath;
}

@end
