//
//  SHKEvernote
//  ShareKit Evernote Additions
//
//  Created by Atsushi Nagase on 8/28/10.
//  Copyright 2010 LittleApps Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHK.h"
#import "SHKSharer.h"

#import "Types.h"
#import "UserStore.h"
#import "NoteStore.h"

#define kENMLPrefix @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\"><en-note style=\"word-wrap: break-word; -webkit-nbsp-mode: space; -webkit-line-break: after-white-space;\">"
#define kENMLSuffix @"</en-note>"

@interface SHKEvernoteItem : SHKItem {}
@property (retain) EDAMNote* note;
@end


@interface SHKEvernote : SHKSharer {}

- (EDAMAuthenticationResult *)getAuthenticationResultForUsername:(NSString *)username password:(NSString *)password;
- (EDAMNotebook *)defaultNoteBookFromNoteStore:(EDAMNoteStoreClient *)noteStore authToken:(NSString *)authToken;
- (NSString *)enMediaTagWithResource:(EDAMResource *)src width:(CGFloat)width height:(CGFloat)height;

@end

