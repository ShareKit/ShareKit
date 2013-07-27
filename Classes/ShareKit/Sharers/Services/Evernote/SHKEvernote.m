//
//  SHKEvernote
//  ShareKit Evernote Additions
//
//  Created by Atsushi Nagase on 8/28/10.
//  Copyright 2010 LittleApps Inc. All rights reserved.
//

#import "SHKEvernote.h"
#import "NSData+md5.h"
#import "EvernoteSDK.h"
#import "GTMNSString+HTML.h"
#import "SharersCommonHeaders.h"

@implementation SHKEvernoteItem
@synthesize note;


@end

@implementation SHKEvernote

- (id)init
{
    self = [super init];
    if (self) {
        [[self class] fillEvernoteSessionWithAppConfig];
    }
    return self;
}

+ (void)fillEvernoteSessionWithAppConfig
{
    NSString *evernoteHost = SHKCONFIG(evernoteHost);
    NSString *consumerKey = SHKCONFIG(evernoteConsumerKey);
    NSString *consumerSecret = SHKCONFIG(evernoteSecret);
    [EvernoteSession setSharedSessionHost:evernoteHost
                              consumerKey:consumerKey 
                           consumerSecret:consumerSecret];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Evernote"); }
+ (BOOL)canShareURL   { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareText  { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file { return YES; }
+ (BOOL)requiresAuthentication { return YES; }


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare {	return YES; }

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized {
    EvernoteSession *session = [EvernoteSession sharedSession];
    return session.isAuthenticated;
}

- (void)promptAuthorization {
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithViewController:[SHK currentHelper].rootViewForUIDisplay completionHandler:^(NSError *error) {
        BOOL success = (error == nil) && session.isAuthenticated;
        [self authDidFinish:success];
        if (error) {
            [[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
                                         message:SHKLocalizedString(@"There was an error while authorizing")
                                        delegate:nil
                                   cancelButtonTitle:SHKLocalizedString(@"Close")
                                   otherButtonTitles:nil] show];
            
        } else if (session.isAuthenticated && self.item) {
            [self tryPendingAction];
        } 
    }];
}

+ (void)logout {
    
    [self fillEvernoteSessionWithAppConfig];
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session logout];
}


#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type 
{
	return [NSArray arrayWithObjects:
	 [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title],
	 //[SHKFormFieldSettings label:SHKLocalizedString(@"Memo")  key:@"text" type:SHKFormFieldTypeText start:self.item.text],
	 [SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag")  key:@"tags" type:SHKFormFieldTypeText start:[self.item.tags componentsJoinedByString:@", "]],
	 nil];
}

#pragma mark -
#pragma mark Implementation

- (BOOL)send {
	if (![self validateItem])
		return NO;
	[self sendDidStart];
    
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    
    SHKEvernoteItem *enItem = nil;
    NSMutableArray *resources = nil;
    EDAMNote *note = nil;
    if([self.item isKindOfClass:[SHKEvernoteItem class]]) {
        enItem = (SHKEvernoteItem *)self.item;
        note = enItem.note;
        resources = [note.resources mutableCopy];
    }
    
    if(!resources)
    	resources = [[NSMutableArray alloc] init];
    if(!note)
    	note = [[EDAMNote alloc] init];
    
    
    EDAMNoteAttributes *atr = [note attributesIsSet] ? note.attributes : [[EDAMNoteAttributes alloc] init];
    
    if(![atr sourceURLIsSet]&&enItem.URL) {
    	[atr setSourceURL:[enItem.URL absoluteString]];
    }
    
    note.title = self.item.title.length > 0 ? self.item.title :( [note titleIsSet] ? note.title : SHKLocalizedString(@"Untitled") );
    
    if(![note tagNamesIsSet]&&self.item.tags)
    	[note setTagNames:[self.item.tags mutableCopy]];
    
    if(![note contentIsSet]) {
        NSMutableString* contentStr = [[NSMutableString alloc] initWithString:kENMLPrefix];
        NSString * strURL = [self.item.URL absoluteString];
        
        // Evernote doesn't accept unenencoded ampersands
        strURL = SHKEncode(strURL);
        
        if(strURL.length>0) {
            if(self.item.title.length>0)
                [contentStr appendFormat:@"<h1><a href=\"%@\">%@</a></h1>",strURL,[self.item.title gtm_stringByEscapingForHTML]];
            [contentStr appendFormat:@"<p><a href=\"%@\">%@</a></p>",strURL,strURL ];
            atr.sourceURL = strURL;
        } else if(self.item.title.length>0)
            [contentStr appendFormat:@"<h1>%@</h1>",[self.item.title gtm_stringByEscapingForHTML]];
        
        if(self.item.text.length>0 )
            [contentStr appendFormat:@"<p>%@</p>", [SHKFlattenHTML(self.item.text, YES) gtm_stringByEscapingForHTML]];
        
        if(self.item.image) {
            EDAMResource *img = [[EDAMResource alloc] init];
            NSData *rawimg = UIImageJPEGRepresentation(self.item.image, 0.6);
            EDAMData *imgd = [[EDAMData alloc] initWithBodyHash:rawimg size:[rawimg length] body:rawimg];
            [img setData:imgd];
            [img setRecognition:imgd];
            [img setMime:@"image/jpeg"];
            [resources addObject:img];
            [contentStr appendString:[NSString stringWithFormat:@"<p>%@</p>",[self enMediaTagWithResource:img width:self.item.image.size.width height:self.item.image.size.height]]];
        }
        
        if(self.item.file) {
            EDAMResource *file = [[EDAMResource alloc] init];	
            EDAMData *filed = [[EDAMData alloc] initWithBodyHash:self.item.file.data size:[self.item.file.data length] body:self.item.file.data];
            [file setData:filed];
            [file setRecognition:filed];
            [file setMime:self.item.file.mimeType];
            [resources addObject:file];
            [contentStr appendString:[NSString stringWithFormat:@"<p>%@</p>",[self enMediaTagWithResource:file width:0 height:0]]];
        }
        [contentStr appendString:kENMLSuffix];
        [note setContent:contentStr];
    }
    
    ////////////////////////////////////////////////
    // Replace <img> HTML elements with en-media elements
  	////////////////////////////////////////////////
    
    for(EDAMResource *res in resources) {
        if(![res dataIsSet]&&[res attributesIsSet]&&res.attributes.sourceURL.length>0&&[res.mime isEqualToString:@"image/jpeg"]) {
            @try {
                NSData *rawimg = [NSData dataWithContentsOfURL:[NSURL URLWithString:res.attributes.sourceURL]];
                UIImage *img = [UIImage imageWithData:rawimg];
                if(img) {
                    EDAMData *imgd = [[EDAMData alloc] initWithBodyHash:rawimg size:[rawimg length] body:rawimg];
                    [res setData:imgd];
                    [res setRecognition:imgd];
                    [note setContent:
                     [note.content stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<img src=\"%@\" />",res.attributes.sourceURL]
                                                             withString:[self enMediaTagWithResource:res width:img.size.width height:img.size.height]]];
                }
            }
            @catch (NSException * e) {
                SHKLog(@"Caught: %@",e);
            }
        }
    }
    [note setResources:resources];
    [note setAttributes:atr];
    [note setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
    
    
    void (^successBlock)(EDAMNote *note) = ^(EDAMNote *note) {        
        [self sendDidFinish];
    };
    void (^failureBlock)(NSError *error) = ^(NSError *error) {
        if (error.code == EDAMErrorCode_INVALID_AUTH || error.code == EDAMErrorCode_AUTH_EXPIRED) {
            [self shouldReloginWithPendingAction:SHKPendingSend];
        } else {
            [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was a problem sharing with Evernote")]];
        }
    };
    
    if(![note notebookGuidIsSet]) {
        [noteStore getDefaultNotebookWithSuccess:^(EDAMNotebook *notebook) {
            [note setNotebookGuid:[notebook guid]];
            [noteStore createNote:note success:successBlock failure:failureBlock];
        } failure:^(NSError *error) {
            if (error.code == EDAMErrorCode_INVALID_AUTH || error.code == EDAMErrorCode_AUTH_EXPIRED) {
                [self shouldReloginWithPendingAction:SHKPendingSend];
            } else {
                [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was a problem sharing with Evernote")]];
                [noteStore createNote:note success:successBlock failure:failureBlock];
            }
        }];
    } else {
        [noteStore createNote:note success:successBlock failure:failureBlock];
    }
	return YES;
}

- (NSString *)enMediaTagWithResource:(EDAMResource *)src width:(CGFloat)width height:(CGFloat)height {
	NSString *sizeAtr = width > 0 && height > 0 ? [NSString stringWithFormat:@"height=\"%.0f\" width=\"%.0f\" ",height,width]:@"";
	return [NSString stringWithFormat:@"<en-media type=\"%@\" %@hash=\"%@\"/>",src.mime,sizeAtr,[src.data.body md5]];
}

@end
