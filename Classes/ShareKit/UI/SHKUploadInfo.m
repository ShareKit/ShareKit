//
//  SHKUploadData.m
//  ShareKit
//
//  Created by Vilém Kurz on 27/01/14.
//
//

#import "SHKUploadInfo.h"

#import "SHKSharer.h"
#import "SHKItem.h"

@implementation SHKUploadInfo

- (instancetype)initWithSharer:(SHKSharer *)sharer {
    
    self = [super init];
    if (self) {
        _sharer = sharer;
        _sharerTitle = [sharer sharerTitle];
        _filename = sharer.item.file.filename;
        _bytesTotal = sharer.item.file.size;
    }
    return self;
}

- (BOOL)isFailed {
    
    BOOL result = !self.uploadFinishedSuccessfully && !self.uploadCancelled && !self.sharer;
    return result;
}

- (BOOL)isInProgress {
    
    BOOL result = !self.uploadFinishedSuccessfully && !self.uploadCancelled && self.sharer;
    return result;
}

- (CGFloat)uploadProgress {
    
    CGFloat result = (CGFloat)self.bytesUploaded / self.bytesTotal;
    
    //workaround for buggy sdk's, e.g Dropbox can upload 1.06 of a file :(
    if (result > 1.0) {
        result = 1.0;
    }
    return result;    
}

#pragma mark - NS Coding

static NSString *sharerTitleKey = @"sharerTitleKey";
static NSString *filenameKey = @"filenameKey";
static NSString *bytesTotalKey = @"bytesTotalKey";
static NSString *bytesUploadedKey = @"bytesUploadedKey";
static NSString *uploadFinishedSuccessfullyKey = @"uploadFinishedSuccessfullyKey";
static NSString *uploadCancelledKey = @"uploadCancelledKey";

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    //we omit sharer. If app shuts down, sharer is deallocated anyway.
    [aCoder encodeObject:self.sharerTitle forKey:sharerTitleKey];
    [aCoder encodeObject:self.filename forKey:filenameKey];
    [aCoder encodeInt64:self.bytesTotal forKey:bytesTotalKey];
    [aCoder encodeInt64:self.bytesUploaded forKey:bytesUploadedKey];
    [aCoder encodeBool:self.uploadFinishedSuccessfully forKey:uploadFinishedSuccessfullyKey];
    [aCoder encodeBool:self.uploadCancelled forKey:uploadCancelledKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if (self) {
        _sharerTitle = [aDecoder decodeObjectForKey:sharerTitleKey];
        _filename = [aDecoder decodeObjectForKey:filenameKey];
        _bytesTotal = [aDecoder decodeInt64ForKey:bytesTotalKey];
        _bytesUploaded = [aDecoder decodeInt64ForKey:bytesUploadedKey];
        _uploadFinishedSuccessfully = [aDecoder decodeBoolForKey:uploadFinishedSuccessfullyKey];
        _uploadCancelled = [aDecoder decodeBoolForKey:uploadCancelledKey];
    }
    return self;
}

@end
