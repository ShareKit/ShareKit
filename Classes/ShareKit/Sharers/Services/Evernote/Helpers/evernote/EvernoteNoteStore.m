/*
 * EvernoteNoteStore.m
 * evernote-sdk-ios
 *
 * Copyright 2012 Evernote Corporation
 * All rights reserved. 
 * 
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *  
 * 1. Redistributions of source code must retain the above copyright notice, this 
 *    list of conditions and the following disclaimer.
 *     
 * 2. Redistributions in binary form must reproduce the above copyright notice, 
 *    this list of conditions and the following disclaimer in the documentation 
 *    and/or other materials provided with the distribution.
 *  
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "EvernoteNoteStore.h"

@implementation EvernoteNoteStore

+ (EvernoteNoteStore *)noteStore
{
    EvernoteNoteStore *noteStore = [[[EvernoteNoteStore alloc] initWithSession:[EvernoteSession sharedSession]] autorelease];
    return noteStore;
}

- (id)initWithSession:(EvernoteSession *)session
{
    self = [super initWithSession:session];
    if (self) {
    }
    return self;
}

#pragma mark - NoteStore sync methods

- (void)getSyncStateWithSuccess:(void(^)(EDAMSyncState *syncState))success 
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getSyncState:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)getSyncChunkAfterUSN:(int32_t)afterUSN 
                  maxEntries:(int32_t)maxEntries
                fullSyncOnly:(BOOL)fullSyncOnly
                     success:(void(^)(EDAMSyncChunk *syncChunk))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getSyncChunk:self.session.authenticationToken:afterUSN:maxEntries:fullSyncOnly];
    } success:success failure:failure];
}

- (void)getFilteredSyncChunkAfterUSN:(int32_t)afterUSN
                          maxEntries:(int32_t)maxEntries
                              filter:(EDAMSyncChunkFilter *)filter
                             success:(void(^)(EDAMSyncChunk *syncChunk))success
                             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getFilteredSyncChunk:self.session.authenticationToken:afterUSN:maxEntries:filter];
    } success:success failure:failure];
}

- (void)getLinkedNotebookSyncState:(EDAMLinkedNotebook *)linkedNotebook
                           success:(void(^)(EDAMSyncState *syncState))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getLinkedNotebookSyncState:self.session.authenticationToken:linkedNotebook];
    } success:success failure:failure];
}

#pragma mark - NoteStore notebook methods

- (void)listNotebooksWithSuccess:(void(^)(NSArray *notebooks))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listNotebooks:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)getNotebookWithGuid:(EDAMGuid)guid 
                    success:(void(^)(EDAMNotebook *syncState))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNotebook:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getLinkedNotebookSyncChunk:(EDAMLinkedNotebook *)linkedNotebook
                          afterUSN:(int32_t)afterUSN
                        maxEntries:(int32_t) maxEntries
                      fullSyncOnly:(BOOL)fullSyncOnly
                           success:(void(^)(EDAMSyncChunk *syncChunk))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getLinkedNotebookSyncChunk:self.session.authenticationToken:linkedNotebook:afterUSN:maxEntries:fullSyncOnly];
    } success:success failure:failure];
}

- (void)getDefaultNotebookWithSuccess:(void(^)(EDAMNotebook *notebook))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getDefaultNotebook:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)createNotebook:(EDAMNotebook *)notebook
               success:(void(^)(EDAMNotebook *notebook))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore createNotebook:self.session.authenticationToken:notebook];
    } success:success failure:failure];
}

- (void)updateNotebook:(EDAMNotebook *)notebook
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore updateNotebook:self.session.authenticationToken:notebook];
    } success:success failure:failure];
}

- (void)expungeNotebookWithGuid:(EDAMGuid)guid
                        success:(void(^)(int32_t usn))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeNotebook:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore tags methods

- (void)listTagsWithSuccess:(void(^)(NSArray *tags))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listTags:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)listTagsByNotebookWithGuid:(EDAMGuid)guid
                           success:(void(^)(NSArray *tags))success
                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listTagsByNotebook:self.session.authenticationToken:guid];
    } success:success failure:failure];
};

- (void)getTagWithGuid:(EDAMGuid)guid
               success:(void(^)(EDAMTag *tag))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getTag:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)createTag:(EDAMTag *)tag
          success:(void(^)(EDAMTag *tag))success
          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore createTag:self.session.authenticationToken:tag];
    } success:success failure:failure];
}

- (void)updateTag:(EDAMTag *)tag
          success:(void(^)(int32_t usn))success
          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore updateTag:self.session.authenticationToken:tag];
    } success:success failure:failure];
}

- (void)untagAllWithGuid:(EDAMGuid)guid
                 success:(void(^)())success
                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncVoidBlock:^() {
        [self.noteStore untagAll:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)expungeTagWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeTag:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore search methods

- (void)listSearchesWithSuccess:(void(^)(NSArray *searches))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listSearches:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)getSearchWithGuid:(EDAMGuid)guid
                  success:(void(^)(EDAMSavedSearch *search))success
                  failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getSearch:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)createSearch:(EDAMSavedSearch *)search
             success:(void(^)(EDAMSavedSearch *search))success
             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore createSearch:self.session.authenticationToken:search];
    } success:success failure:failure];
}

- (void)updateSearch:(EDAMSavedSearch *)search
             success:(void(^)(int32_t usn))success
             failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore updateSearch:self.session.authenticationToken:search];
    } success:success failure:failure];
}

- (void)expungeSearchWithGuid:(EDAMGuid)guid
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeSearch:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore notes methods

- (void)findNotesWithFilter:(EDAMNoteFilter *)filter 
                     offset:(int32_t)offset
                   maxNotes:(int32_t)maxNotes
                    success:(void(^)(EDAMNoteList *search))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore findNotes:self.session.authenticationToken:filter:offset:maxNotes];
    } success:success failure:failure];
}

- (void)findNoteOffsetWithFilter:(EDAMNoteFilter *)filter 
                            guid:(EDAMGuid)guid
                         success:(void(^)(int32_t offset))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore findNoteOffset:self.session.authenticationToken:filter:guid];
    } success:success failure:failure];
}

- (void)findNotesMetadataWithFilter:(EDAMNoteFilter *)filter
                             offset:(int32_t)offset 
                           maxNotes:(int32_t)maxNotes 
                         resultSpec:(EDAMNotesMetadataResultSpec *)resultSpec
                            success:(void(^)(EDAMNotesMetadataList *metadata))success
                            failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore findNotesMetadata:self.session.authenticationToken:filter:offset:maxNotes:resultSpec];
    } success:success failure:failure];
}

- (void)findNoteCountsWithFilter:(EDAMNoteFilter *)filter 
                       withTrash:(BOOL)withTrash
                         success:(void(^)(EDAMNoteCollectionCounts *counts))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore findNoteCounts:self.session.authenticationToken:filter:withTrash];
    } success:success failure:failure];
}

- (void)getNoteWithGuid:(EDAMGuid)guid 
            withContent:(BOOL)withContent 
      withResourcesData:(BOOL)withResourcesData 
withResourcesRecognition:(BOOL)withResourcesRecognition 
withResourcesAlternateData:(BOOL)withResourcesAlternateData
                success:(void(^)(EDAMNote *note))success
                failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNote:self.session.authenticationToken:guid:withContent:withResourcesData:withResourcesRecognition:withResourcesAlternateData];
    } success:success failure:failure];
}

- (void)getNoteApplicationDataWithGuid:(EDAMGuid)guid
                               success:(void(^)(EDAMLazyMap *map))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNoteApplicationData:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getNoteApplicationDataEntryWithGuid:(EDAMGuid)guid 
                                        key:(NSString *)key
                                    success:(void(^)(NSString *entry))success
                                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNoteApplicationDataEntry:self.session.authenticationToken:guid:key];
    } success:success failure:failure];
}

- (void)setNoteApplicationDataEntryWithGuid:(EDAMGuid)guid 
                                        key:(NSString *)key 
                                      value:(NSString *)value
                                    success:(void(^)(int32_t usn))success
                                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore setNoteApplicationDataEntry:self.session.authenticationToken:guid:key:value];
    } success:success failure:failure];
}

- (void)unsetNoteApplicationDataEntryWithGuid:(EDAMGuid)guid 
                                          key:(NSString *) key
                                      success:(void(^)(int32_t usn))success
                                      failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore unsetNoteApplicationDataEntry:self.session.authenticationToken:guid:key];
    } success:success failure:failure];
}

- (void)getNoteContentWithGuid:(EDAMGuid)guid
                       success:(void(^)(NSString *content))success
                       failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNoteContent:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getNoteSearchTextWithGuid:(EDAMGuid)guid 
                         noteOnly:(BOOL)noteOnly
              tokenizeForIndexing:(BOOL)tokenizeForIndexing
                          success:(void(^)(NSString *text))success
                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNoteSearchText:self.session.authenticationToken:guid:noteOnly:tokenizeForIndexing];
    } success:success failure:failure];
}

- (void)getResourceSearchTextWithGuid:(EDAMGuid)guid
                              success:(void(^)(NSString *text))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceSearchText:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getNoteTagNamesWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSArray *names))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNoteTagNames:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)createNote:(EDAMNote *)note
           success:(void(^)(NSString *note))success
           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore createNote:self.session.authenticationToken:note];
    } success:success failure:failure];
}

- (void)updateNote:(EDAMNote *)note
           success:(void(^)(NSString *note))success
           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore updateNote:self.session.authenticationToken:note];
    } success:success failure:failure];
}

- (void)deleteNoteWithGuid:(EDAMGuid)guid
                   success:(void(^)(int32_t usn))success
                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore deleteNote:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)expungeNoteWithGuid:(EDAMGuid)guid
                    success:(void(^)(int32_t usn))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeNote:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)expungeNotesWithGuids:(NSArray *)guids
                      success:(void(^)(int32_t usn))success
                      failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeNotes:self.session.authenticationToken:guids];
    } success:success failure:failure];
}

- (void)expungeInactiveNoteWithSuccess:(void(^)(int32_t usn))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeInactiveNotes:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)copyNoteWithGuid:(EDAMGuid)guid 
          toNoteBookGuid:(EDAMGuid)toNotebookGuid
                 success:(void(^)(EDAMNote *note))success
                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore copyNote:self.session.authenticationToken:guid:toNotebookGuid];
    } success:success failure:failure];
}

- (void)listNoteVersionsWithGuid:(EDAMGuid)guid
                         success:(void(^)(NSArray *versions))success
                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listNoteVersions:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getNoteVersionWithGuid:(EDAMGuid)guid 
             updateSequenceNum:(int32_t)updateSequenceNum 
             withResourcesData:(BOOL)withResourcesData 
      withResourcesRecognition:(BOOL)withResourcesRecognition 
    withResourcesAlternateData:(BOOL)withResourcesAlternateData
                       success:(void(^)(EDAMNote *note))success
                       failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getNoteVersion:self.session.authenticationToken:guid:updateSequenceNum:withResourcesData:withResourcesRecognition:withResourcesAlternateData];
    } success:success failure:failure];
}

#pragma mark - NoteStore resource methods

- (void)getResourceWithGuid:(EDAMGuid)guid 
                   withData:(BOOL)withData 
            withRecognition:(BOOL)withRecognition 
             withAttributes:(BOOL)withAttributes 
          withAlternateDate:(BOOL)withAlternateData
                    success:(void(^)(EDAMResource *resource))success
                    failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResource:self.session.authenticationToken:guid:withData:withRecognition:withAttributes:withAlternateData];
    } success:success failure:failure];
}

- (void)getResourceApplicationDataWithGuid:(EDAMGuid)guid
                                   success:(void(^)(EDAMLazyMap *map))success
                                   failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceApplicationData:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getResourceApplicationDataEntryWithGuid:(EDAMGuid)guid 
                                            key:(NSString *)key
                                        success:(void(^)(NSString *entry))success
                                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceApplicationDataEntry:self.session.authenticationToken:guid:key];
    } success:success failure:failure];
}

- (void)setResourceApplicationDataEntryWithGuid:(EDAMGuid)guid 
                                            key:(NSString *)key 
                                          value:(NSString *)value
                                        success:(void(^)(int32_t usn))success
                                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore setResourceApplicationDataEntry:self.session.authenticationToken:guid:key:value];
    } success:success failure:failure];
}

- (void)unsetResourceApplicationDataEntryWithGuid:(EDAMGuid)guid 
                                              key:(NSString *)key
                                          success:(void(^)(int32_t usn))success
                                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore unsetResourceApplicationDataEntry:self.session.authenticationToken:guid:key];
    } success:success failure:failure];
}

- (void)updateResource:(EDAMResource *)resource
               success:(void(^)(int32_t usn))success
               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore updateResource:self.session.authenticationToken:resource];
    } success:success failure:failure];
}

- (void)getResourceDataWithGuid:(EDAMGuid)guid
                        success:(void(^)(NSData *data))success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceData:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getResourceByHashWithGuid:(EDAMGuid)guid 
                      contentHash:(NSData *)contentHash 
                         withData:(BOOL)withData 
                  withRecognition:(BOOL)withRecognition 
                withAlternateData:(BOOL)withAlternateData
                          success:(void(^)(EDAMResource *resource))success
                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceByHash:self.session.authenticationToken:guid:contentHash:withData:withRecognition:withAlternateData];
    } success:success failure:failure];
}

- (void)getResourceRecognitionWithGuid:(EDAMGuid)guid
                               success:(void(^)(NSData *data))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceRecognition:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getResourceAlternateDataWithGuid:(EDAMGuid)guid
                                 success:(void(^)(NSData *data))success
                                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceAlternateData:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)getResourceAttributesWithGuid:(EDAMGuid)guid
                              success:(void(^)(EDAMResourceAttributes *attributes))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getResourceAttributes:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

#pragma mark - NoteStore ad methods

- (void)getAdsWithParameters:(EDAMAdParameters *)adParameters
                     success:(void(^)(NSArray *ads))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getAds:self.session.authenticationToken:adParameters];
    } success:success failure:failure];
}

- (void)getRandomAdWithParameters:(EDAMAdParameters *)adParameters
                          success:(void(^)(EDAMAd *ad))success
                          failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getRandomAd:self.session.authenticationToken:adParameters];
    } success:success failure:failure];
}

#pragma mark - NoteStore shared notebook methods

- (void)getPublicNotebookWithUserID:(EDAMUserID)userId 
                          publicUri:(NSString *)publicUri
                            success:(void(^)(EDAMNotebook *notebook))success
                            failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getPublicNotebook:userId:publicUri];
    } success:success failure:failure];
}

- (void)createSharedNotebook:(EDAMSharedNotebook *)sharedNotebook
                     success:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                     failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore createSharedNotebook:self.session.authenticationToken:sharedNotebook];
    } success:success failure:failure];
}

- (void)sendMessageToSharedNotebookMembersWithGuid:(EDAMGuid)guid 
                                       messageText:(NSString *)messageText 
                                        recipients:(NSArray *)recipients
                                           success:(void(^)(int32_t numMessagesSent))success
                                           failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore sendMessageToSharedNotebookMembers:self.session.authenticationToken:guid:messageText:recipients];
    } success:success failure:failure];
}

- (void)listSharedNotebooksWithSuccess:(void(^)(NSArray *sharedNotebooks))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listSharedNotebooks:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)expungeSharedNotebooksWithIds:(NSArray *)sharedNotebookIds
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeSharedNotebooks:self.session.authenticationToken:sharedNotebookIds];
    } success:success failure:failure];
}

- (void)createLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(EDAMLinkedNotebook *linkedNotebooks))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore createLinkedNotebook:self.session.authenticationToken:linkedNotebook];
    } success:success failure:failure];
}

- (void)updateLinkedNotebook:(EDAMLinkedNotebook *)linkedNotebook
                     success:(void(^)(int32_t usn))success
                     failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore updateLinkedNotebook:self.session.authenticationToken:linkedNotebook];
    } success:success failure:failure];
}

- (void)listLinkedNotebooksWithSuccess:(void(^)(NSArray *linkedNotebooks))success
                               failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore listLinkedNotebooks:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)expungeLinkedNotebookWithGuid:(EDAMGuid)guid
                              success:(void(^)(int32_t usn))success
                              failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncInt32Block:^int32_t() {
        return [self.noteStore expungeLinkedNotebook:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)authenticateToSharedNotebookWithShareKey:(NSString *)shareKey 
                                         success:(void(^)(EDAMAuthenticationResult *result))success
                                         failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore authenticateToSharedNotebook:self.session.authenticationToken:shareKey];
    } success:success failure:failure];
}

- (void)getSharedNotebookByAuthWithSuccess:(void(^)(EDAMSharedNotebook *sharedNotebook))success
                                   failure:(void(^)(NSError *error))failure

{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore getSharedNotebookByAuth:self.session.authenticationToken];
    } success:success failure:failure];
}

- (void)emailNoteWithParameters:(EDAMNoteEmailParameters *)parameters
                        success:(void(^)())success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncVoidBlock:^() {
        [self.noteStore emailNote:self.session.authenticationToken:parameters];
    } success:success failure:failure];
}

- (void)shareNoteWithGuid:(EDAMGuid)guid
                  success:(void(^)(NSString *noteKey))success
                  failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore shareNote:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)stopSharingNoteWithGuid:(EDAMGuid)guid
                        success:(void(^)())success
                        failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncVoidBlock:^() {
        [self.noteStore stopSharingNote:self.session.authenticationToken:guid];
    } success:success failure:failure];
}

- (void)authenticateToSharedNoteWithGuid:(NSString *)guid 
                                 noteKey:(NSString *)noteKey
                                 success:(void(^)(EDAMAuthenticationResult *result))success
                                 failure:(void(^)(NSError *error))failure
{
    [self invokeAsyncIdBlock:^id() {
        return [self.noteStore authenticateToSharedNote:self.session.authenticationToken:noteKey];
    } success:success failure:failure];
}

@end
