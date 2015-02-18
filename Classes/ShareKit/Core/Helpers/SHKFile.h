//
//  SHKFile.h
//  ShareKit
//
//  Created by Jacob Dunn on 3/5/13.
//
//

#import <Foundation/Foundation.h>

@interface SHKFile : NSObject <NSCoding>

/*! 
 Returns true, if the file is saved on the disc, in opposite to be a representation of in-memory data.
 */
@property (nonatomic,readonly) BOOL hasPath;
/*!
    Returns true, if the file a representation of in-memory data. Returns false, if the file is saved on the disc.
 */
@property (nonatomic,readonly) BOOL hasData;

/**
 * One of these are null by default.
 * Use hasPath or hasData to check beforehand, if you don't
 * require one or the other.
 *
 * On first call, a value will be created for either, if necessary
 *
 * PLEASE NOTE: retrieving path will write the data to a temporary file.
 * This is potentially time intensive, it may be worth doing in the background
 */

/*!
  Use with caution. You should first check if the [file hasPath]. If does not, try to avoid calling this, as retrieving path of in-memory data file will write it to a temporary file, which may be time intensive. If you have to, consider doing this in the background.
 */
@property (nonatomic,readonly) NSString *path;
/*!
 Derived from path. Use with caution. You should first check if the [file hasPath]. If does not, try to avoid calling this, as retrieving path of in-memory data file will write it to a temporary file, which may be time intensive. If you have to, consider doing this in the background.
 */
@property (nonatomic,readonly) NSURL *URL;
/*!
    Use with caution. You should first check if the [file hasData]. If it does not, try to avoid calling this, because retrieving data of a on-disc file will read it to the memory. This may fill up the memory in case of a large file.
 */
@property (nonatomic,readonly) NSData *data;
@property (nonatomic,readonly) NSString *filename;

/*!
    Derived from filename. Used by services to check, if they can handle the file. Also favorites are different for each mime type.
 */
@property (nonatomic,readonly) NSString *mimeType;
/*!
 Derived from filename. Used by services to check, if they can handle the file.
 */
@property (nonatomic,readonly) NSString *UTIType;
/*!
    Size in bytes
 */
@property (nonatomic,readonly) NSUInteger size;
/*!
    This requires a path. Avoid if you don't need it.
 */
@property (nonatomic,readonly) NSUInteger duration;

/**
 * The preferred method for creating a file, with a path
 *
 * @param path Path to the file
 */
- (id)initWithFilePath:(NSString *)path;

/**
 * A fallback for file creation, where we just get the data
 *
 * @param data File data
 * @param filename Filename
 */
- (id)initWithFileData:(NSData *)data filename:(NSString *)filename;

/**
 * Convenience method useful for sharers utilizing UIDocumentInteractionController. Make sure you delete the file after use - the best place to do so is in UIDocumentInteractionControllerDelegate callback.
 *
 * @param extension Extension for a particular app. Without dot.
 *
 * @result NSString path of a new file copy
 */
- (NSString *)makeTemporaryUIDICCopyWithFileExtension:(NSString *)extension;

@end
