//
//  SHKOneNote.m
//
//  Copyright (c) Microsoft Corporation
//  All rights reserved.
//
//  MIT License:
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  ""Software""), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#import "SHKOneNote.h"
#import "SHKConfiguration.h"
#import "SHK.h"
#import "LiveSDK/LiveConnectClient.h"
#import "ISO8601DateFormatter.h"
#import "SHKFormFieldSettings.h"
#import "SHKFormFieldLargeTextSettings.h"
#import "SHKRequest.h"
#import "SHKSharer_protected.h"
#import "PKMultipartInputStream.h"
#import "SHKSession.h"
#import "Debug.h"
#import "NSMutableURLRequest+Parameters.h"

static NSString * const OneNoteHost = @"https://www.onenote.com/api/v1.0/pages";

@interface OneNoteController : NSObject <LiveAuthDelegate>
    @property(strong, nonatomic) SHKOneNote *owner;
@end

@implementation OneNoteController
- (void)authCompleted:(LiveConnectSessionStatus)status
              session:(LiveConnectSession *)session
            userState:(id)userState {
    if ([userState isEqual:@"signin"]) {
        if (session != nil) {
            [self.owner tryPendingAction];
        }
    }
}

- (void)authFailed:(NSError *)error
         userState:(id)userState {
    [[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
                                message:SHKLocalizedString(@"There was an error while authorizing")
                               delegate:nil
                      cancelButtonTitle:SHKLocalizedString(@"Close")
                      otherButtonTitles:nil] show];
}

@end

@interface SHKOneNote ()

+ (LiveConnectClient *)sharedClient;

+ (OneNoteController *)sharedController;

- (void)sendText;

- (void)sendImage;

- (void)sendTextAndLink;

- (void)sendFile;

+ (NSString *)getDate;

@end

@implementation SHKOneNote

#pragma mark - Configuration : Service Definition

+ (NSString *)sharerTitle {
    return SHKLocalizedString(@"OneNote");
}

+ (BOOL)canShareURL {
    return YES;
}

+ (BOOL)canShareImage {
    return YES;
}

+ (BOOL)canShareText {
    return YES;
}

+ (BOOL)canShareFile:(SHKFile *)file {
    return YES;  //{ return [file.mimeType hasPrefix:@"image/"]; }
}

+ (BOOL)canShare {
    return YES;
}

+ (BOOL)canShareOffline {
    return NO;
}

+ (BOOL)canAutoShare {
    return YES;
}

+ (LiveConnectClient *)sharedClient {
    static LiveConnectClient *sharedClient;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedClient = [[LiveConnectClient alloc] initWithClientId:SHKCONFIG(onenoteClientId) delegate:nil];
    });
    return sharedClient;
}

+ (OneNoteController *)sharedController {
    static OneNoteController *sharedController;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedController = [[OneNoteController alloc] init];
    });
    return sharedController;
}


- (id)init {
    if (self = [super init]) {
        OneNoteController *sharedController = [SHKOneNote sharedController];
        sharedController.owner = self;
    }
    return self;
}

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized {
    return [SHKOneNote sharedClient].session.accessToken != nil;
}

- (void)authorizationFormShow {
    [[SHKOneNote sharedClient] login:[SHK currentHelper].rootViewForUIDisplay
                              scopes:[NSArray arrayWithObjects:@"office.onenote_create", @"wl.signin", @"wl.offline_access", nil]
                            delegate: [SHKOneNote sharedController]
                           userState:@"signin"];
}

- (void)logout {
    [[SHKOneNote sharedClient] logout];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
    NSString *text;
    NSString *key;
    BOOL allowEmptyMessage = NO;
    
    switch (self.item.shareType) {
        case SHKShareTypeText:
            text = self.item.text;
            key = @"text";
            break;
        case SHKShareTypeImage:
            text = self.item.title;
            key = @"title";
            allowEmptyMessage = YES;
            break;
        case SHKShareTypeURL:
            text = self.item.text;
            key = @"text";
            allowEmptyMessage = YES;
            break;
        case SHKShareTypeFile:
            text = self.item.text;
            key = @"text";
            break;
        default:
            return nil;
    }
    
    SHKFormFieldLargeTextSettings *commentField = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Comment")
                                                                                   key:key
                                                                                 start:text
                                                                                  item:self.item];
    commentField.select = YES;
    commentField.validationBlock = ^(SHKFormFieldLargeTextSettings *formFieldSettings) {
        BOOL result;
        if (allowEmptyMessage) {
            result = YES;
        } else {
            result = [formFieldSettings.valueToSave length] > 0;
        }
        return result;
    };
    
    NSMutableArray *result = [@[commentField] mutableCopy];
    
    if (self.item.shareType == SHKShareTypeURL || self.item.shareType == SHKShareTypeFile) {
        SHKFormFieldSettings *title = [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title];
        [result insertObject:title atIndex:0];
    }
    return result;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send {
    if (![self validateItem])
        return NO;

    //[self setQuiet:NO];

    switch (self.item.shareType) {
        case SHKShareTypeURL:
            [self sendTextAndLink];
            break;
        case SHKShareTypeText:
            [self sendText];
            break;
        case SHKShareTypeImage:
            [self sendImage];
            break;
        case SHKShareTypeFile:
            [self sendFile];
            break;
        default:
            return NO;
    }

    [self sendDidStart];
    return YES;
}

- (void)sendText {
    
    NSMutableURLRequest *multipartrequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:OneNoteHost]];
    multipartrequest.HTTPMethod = @"POST";
    
    NSString *defaultTitle = @"Sharing Text via ShareKit";
    
    NSData *presentation = [self htmlDataWithBody:self.item.text defaultTitle:defaultTitle];
    
    [multipartrequest attachData:presentation withParameterName:@"Presentation" contentType:@"text/html"];
    
    [self send:multipartrequest trySession:NO];
}

- (void)sendImage {
    
    NSMutableURLRequest *multipartrequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:OneNoteHost]];
    multipartrequest.HTTPMethod = @"POST";
    
    NSString *defaultTitle = @"Sharing an Image via ShareKit";
    
    NSString *bodyString = [[NSString alloc] initWithFormat:@"<img src=\"name:image1\" width=\"%.0f\" height=\"%.0f\" />", self.item.image.size.width, self.item.image.size.height];
    
    NSData *presentation = [self htmlDataWithBody:bodyString defaultTitle:defaultTitle];
    
    [multipartrequest attachData:presentation withParameterName:@"Presentation" contentType:@"text/html"];
    
    [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:1.0];
    [multipartrequest attachFile:self.item.file withParameterName:@"image1"];
    
    [self send:multipartrequest trySession:YES];
}

- (void)sendTextAndLink {
    
    NSMutableURLRequest *multipartrequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:OneNoteHost]];
    multipartrequest.HTTPMethod = @"POST";
    
    NSString *defaultTitle = @"Sharing a Link via ShareKit";
    
    NSString *strURL = [self.item.URL absoluteString];
    NSString *bodyString = [[NSString alloc] initWithFormat:@"<p><div>%@</div><br/><a href=\"%@\">%@</a></p> <img data-render-src=\"%@\"/></body></html>", self.item.text, strURL, strURL, strURL];
    
    NSData *presentation = [self htmlDataWithBody:bodyString defaultTitle:defaultTitle];
    
    [multipartrequest attachData:presentation withParameterName:@"Presentation" contentType:@"text/html"];
    
    if (self.item.image) {
        [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:1.0];
        [multipartrequest attachFile:self.item.file withParameterName:@"image1"];
    }
    
    BOOL trySession = self.item.file != nil;
    [self send:multipartrequest trySession:trySession];
}

- (void)sendFile {
    
//#warning TODO: comment field omitted?
    NSMutableURLRequest *multipartrequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:OneNoteHost]];
    multipartrequest.HTTPMethod = @"POST";

    NSString *defaultTitle = @"Sharing a File via ShareKit";
    
    NSString *bodyString = [[NSString alloc] initWithFormat:@"<object data-attachment=\"%@\" data=\"name:embedded1\" type=\"%@\" />",
    self.item.file.filename, self.item.file.mimeType];
    
    NSData *simpleHTMLdata = [self htmlDataWithBody:bodyString defaultTitle:defaultTitle];
    
    if (self.item.file.hasPath) { //we use streaming, without loading complete file into memory
        
        PKMultipartInputStream *stream = [[PKMultipartInputStream alloc] init];
        [stream addPartWithName:@"Presentation" data:simpleHTMLdata contentType:@"text/html"];
        [stream addPartWithName:@"embedded1" filename:self.item.file.filename path:self.item.file.path];
        multipartrequest.HTTPBodyStream = stream;
        
        [multipartrequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [stream boundary]] forHTTPHeaderField:@"Content-Type"];

    } else {
        
        [multipartrequest attachData:simpleHTMLdata withParameterName:@"Presentation" contentType:@"text/html"];
        [multipartrequest attachFile:self.item.file withParameterName:@"embedded1"];
    }
    
    [self send:multipartrequest trySession:YES];
}

- (NSData *)htmlDataWithBody:(NSString *)body defaultTitle:(NSString *)defaultTitle {
    
    NSString *date = [SHKOneNote getDate];
    NSString *title = self.item.title ? self.item.title : defaultTitle;
    NSString *simpleHtml = [NSString stringWithFormat:
                            @"<html><head><title>%@</title><meta name=\"created\" content=\"%@\" /></head><body>",
                            title, date];
    simpleHtml = [simpleHtml stringByAppendingString:body];
    simpleHtml = [simpleHtml stringByAppendingString:@"</body></html>"];
    NSData *result = [simpleHtml dataUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (void)send:(NSMutableURLRequest *)multipartrequest trySession:(BOOL)trySession {
    
    if ([SHKOneNote sharedClient].session) {
        [multipartrequest setValue:[@"Bearer " stringByAppendingString:[SHKOneNote sharedClient].session.accessToken] forHTTPHeaderField:@"Authorization"];
    }
    
    BOOL canUseNSURLSession = NSClassFromString(@"NSURLSession") != nil;
    
    if (trySession && canUseNSURLSession) {
        
        __weak typeof(self) weakSelf = self;
        self.networkSession = [SHKSession startSessionWithRequest:multipartrequest delegate:self completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (error.code == -999) {
                [weakSelf sendDidCancel];
            } else if (error) {
                SHKLog(@"SHKOneNote upload file did fail with error:%@", [error description]);
                [self sendShowSimpleErrorAlert];
            } else {
                BOOL success = [(NSHTTPURLResponse *)response statusCode] < 400;
                if (success) {
                    [self sendFinishedSuccessfullyWithData:data];
                } else {
//#warning TODO: revoked access error handling
                    [self sendShowSimpleErrorAlert];
                }
            }
        }];
        
    } else {
        
        SHKRequest *request = [[SHKRequest alloc] initWithRequest:multipartrequest
                                                       completion:^(SHKRequest *request) {
                                                           if (request.success) {
                                                               [self sendFinishedSuccessfullyWithData:request.data];
                                                           } else {
                                                               [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was a problem sharing with OneNote")]];
                                                           }
                                                       }];
        [request start];
    }
}

- (void)sendFinishedSuccessfullyWithData:(NSData *)data {
    
    NSError *error;
    NSDictionary *parsedResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    [self sendDidFinishWithResponse:parsedResponse];
}

//- (NSString *)enMediaTagWithResource:(SHKFile *)file width:(CGFloat)width height:(CGFloat)height {
//    NSString *sizeAtr = width > 0 && height > 0 ? [NSString stringWithFormat:@"height=\"%.0f\" width=\"%.0f\" ",height,width]:@"";
//    return [NSString stringWithFormat:@"<en-media type=\"%@\" %@hash=\"%@\"/>",src.mime,sizeAtr,[src.data.body md5]];
//}

#pragma mark -
#pragma mark Helpers
// Get a date in ISO8601 string format
+ (NSString *)getDate {
    ISO8601DateFormatter *isoFormatter = [[ISO8601DateFormatter alloc] init];
    [isoFormatter setDefaultTimeZone:[NSTimeZone localTimeZone]];
    [isoFormatter setIncludeTime:YES];
    NSString *date = [isoFormatter stringFromDate:[NSDate date]];
    return date;
}

@end