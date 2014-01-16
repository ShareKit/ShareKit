//
//  NSData+SaveItemAttachment.h
//  ShareKit
//
//  Created by Vilem Kurz on 06/03/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSData (SaveItemAttachment)

//saves the attachment to SHKAttachmentSaveDir (defined in SHKItem) and returns bookmark of saved attachment
- (NSData *)saveAttachmentData;
- (NSData *)restoreDataFromAttachmentBookmark;

@end
