//
//  SHKSharer+Video.h
//  ShareKit
//
//  Created by Jacob Dunn on 2/28/13.
//
//

#import "SHKSharer.h"

@interface SHKSharer (Video)

/**
 * Checks to make sure the file extension is valid.
 *
 * @param validTypes An array of NSString file extensions
 */
-(BOOL)isOfValidTypes:(NSArray*)validTypes;


/**
 * Checks if file size is below limits.
 *
 * @param maxSize Size of the file, in bytes
 */
-(BOOL)isUnderSize:(NSInteger)maxSize;

/**
 * Checks if video duration is below limits.
 *
 * @param maxDuration Length, in seconds
 */
-(BOOL)isUnderDuration:(NSInteger)maxDuration;

@end
