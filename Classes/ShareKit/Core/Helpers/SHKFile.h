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


/*
 * Our properties. You can override filename and mimeType, if you desire.
 */
@property (nonatomic,strong) NSString *filename;
@property (nonatomic,strong) NSString *mimeType;
@property (nonatomic,readonly) NSUInteger size;

// This requires a path. Avoid if you don't need it.
@property (nonatomic,readonly) NSUInteger duration;

/**
 * The preferred method for creating a file, with a path
 *
 * @param path Path to the file
 */
- (id)initWithFile:(NSString *)path;

/**
 * A fallback for file creation, where we just get the data
 *
 * @param data File data
 * @param filename Filename
 * @param mimetype File MymeType
 */
- (id)initWithFile:(NSData *)data filename:(NSString *)filename;

@end
