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

@interface SHKFile()

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic) NSUInteger size;
@property (nonatomic) NSUInteger duration;

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
    [_path release];
    [_data release];
    [_filename release];
    [_mimeType release];
    [super dealloc];
}

- (id)initWithFile:(NSString *)path {
    
    self = [super init];
    
    if (self) {
        
        _path = [path retain];
        _filename = [path.lastPathComponent retain];
        _mimeType = [[self MIMETypeForPath:self.filename] retain];
    }
    return self;
}

- (id)initWithFile:(NSData *)data filename:(NSString *)filename {
    
    self = [super init];
    
    if (self) {
        
        _data = [data retain];
        
        if (!filename) filename = [NSString stringWithFormat:@"ShareKit_file_%li", random() % 100];
        
        _filename = [filename retain];
        _mimeType = [[self MIMETypeForPath:self.filename] retain];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {

    self = [super init];
    
    if (self) {
        
        _path = [[decoder decodeObjectForKey:kSHKFilePath] retain];
        
        if (_path) {
            
            _filename = [_path.lastPathComponent retain];
            _mimeType = [[self MIMETypeForPath:_filename] retain];
        
        } else {
            
            _data = [[decoder decodeObjectForKey:kSHKFileData] retain];
            _filename = [[decoder decodeObjectForKey:kSHKFileName] retain];
            _mimeType = [[self MIMETypeForPath:_filename] retain];
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
    // Generate a unique id for the share to use when saving associated files
    NSString *uid = [tempDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"SHKfile-%f-%i.",[[NSDate date] timeIntervalSince1970], arc4random()]];
    
    // Our filename
    _path = [[uid stringByAppendingPathExtension:self.filename] retain];
    
    // Create our file
    if([[NSFileManager defaultManager] fileExistsAtPath:_path]) {
        // TODO: This file already exists - throw an error
    }
    
    // Read our file into the file system
    [_data writeToFile:_path atomically:YES];
}

-(void)createDataFromPath
{
    NSError *error;
    _data = [[NSData dataWithContentsOfFile:_path options:NSDataReadingMapped|NSDataReadingUncached error:&error] retain];
    
    if(error){
        // TODO: Handle this error
    }
}

-(void)removeTempFile
{
    if(!self.hasPath || [self.path rangeOfString:tempDirectory].location == NSNotFound) return;
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
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
    NSString *extension = [path pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    return result;
}

@end
