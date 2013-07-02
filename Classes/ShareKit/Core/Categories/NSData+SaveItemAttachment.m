//
//  NSData+SaveItemAttachment.m
//  ShareKit
//
//  Created by Vilem Kurz on 06/03/2013.
//
//

#import "NSData+SaveItemAttachment.h"
#import "SHKItem.h"
#import "Debug.h"

@implementation NSData (SaveItemAttachment)

- (NSURL *)attachmentSaveDirectory {
    
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSError *error = nil;
    [sharedFM URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL *cachesDir = [sharedFM URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    
    NSURL *result = [cachesDir URLByAppendingPathComponent:SHKAttachmentSaveDir];
    if (result) {
        [sharedFM createDirectoryAtURL:result withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            SHKLog(@"%@", [error description]);
        }
    }
    return result;
}

- (NSData *)saveAttachmentData {

    NSString *uid = [NSString stringWithFormat:@"%f-%i", [[NSDate date] timeIntervalSince1970], arc4random()];
    NSURL *dir = [self attachmentSaveDirectory];
    NSURL *fileURL = [dir URLByAppendingPathComponent:uid];
    [self writeToURL:fileURL atomically:YES];
    NSData *result = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile includingResourceValuesForKeys:nil relativeToURL:nil error:nil];
    
    return result;
}

- (NSData *)restoreDataFromAttachmentBookmark {
    
    BOOL isStale = NO;
    NSError *error = nil;
    NSURL *fileURL = [NSURL URLByResolvingBookmarkData:self options:NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&isStale error:&error];
    if (isStale || (error != nil)) {
        SHKLog(@"Could not restore attachment, error:%@", [error description]);
        return nil;
    }
    NSData *result = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedAlways error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil]; //clean up
    
    return result;
}

@end
