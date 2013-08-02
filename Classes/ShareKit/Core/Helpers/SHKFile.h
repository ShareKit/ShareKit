//
//  SHKFile.h
//  ShareKit
//
//  Created by Jacob Dunn on 3/5/13.
//
//

#import <Foundation/Foundation.h>

@interface SHKFile : NSObject <NSCoding>

/*
 * Used to see which is set. We prefer path, but it could be either
 */
@property (nonatomic,readonly) BOOL hasPath;
@property (nonatomic,readonly) BOOL hasData;

/*
 * One of these are null by default.
 * Use hasPath or hasData to check beforehand, if you don't
 * require one or the other.
 *
 * On first call, a value will be created for either, if necessary
 *
 * PLEASE NOTE: retrieving path will write the data to a temporary file.
 * This is potentially time intensive, it may be worth doing in the background
 */
@property (nonatomic,readonly) NSString *path;
@property (nonatomic,readonly) NSData *data;
@property (nonatomic,readonly) NSString *filename;

//Derived from filename. Used by services to check, if they can handle the file. Also favorites are different for each mime type.
@property (nonatomic,readonly) NSString *mimeType;

//size in bytes
@property (nonatomic,readonly) NSUInteger size;

// This requires a path. Avoid if you don't need it.
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

//if has path, it is path extension, if has data it is mime type to avoid saving data
- (NSString *)extension;

@end
