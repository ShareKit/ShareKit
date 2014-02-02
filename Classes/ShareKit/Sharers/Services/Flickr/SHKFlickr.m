//
//  SHKFlickr.m
//  ShareKit
//
//  Created by Vilem Kurz on 03/12/2013.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "SHKFlickr.h"

#import "SharersCommonHeaders.h"
#import "SHKOAuthView.h"
#import "NSDictionary+Recursive.h"
#import "SHKXMLResponseParser.h"

#define kSHKFlickrUserInfo @"kSHKFlickrUserInfo"
#define USER_REMOVED_ACCESS_CODE @"98"
#define USER_EXCEEDED_UPLOAD_LIMIT_CODE @"6"

@interface SHKFlickr ()

@property (weak, nonatomic) OAAsynchronousDataFetcher *getGroupsFetcher;

@end

@implementation SHKFlickr

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Flickr"); }

+ (BOOL)canShareImage { return YES; }
+ (BOOL)canGetUserInfo { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file {
    
    NSArray *allowedFileTypes = @[@"image/jpeg",
                                  @"image/png",
                                  @"image/gif",
                                  @"video/avi",
                                  @"video/x-ms-wmv",
                                  @"video/x-msvideo",
                                  @"video/quicktime",
                                  @"video/mpeg",
                                  @"video/3gpp",
                                  @"video/MP2T",
                                  @"video/ogg",
                                  @"video/mp4"];
    
    if ([allowedFileTypes containsObject:file.mimeType]) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Authentication

- (id)init {
    
    self = [super init];
    
	if (self) {
        
		consumerKey = SHKCONFIG(flickrConsumerKey);
		secretKey = SHKCONFIG(flickrSecretKey);
 		authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(flickrCallbackUrl)];
	
	    requestURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/request_token"];
	    authorizeURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/authorize"];
	    accessURL = [NSURL URLWithString:@"http://www.flickr.com/services/oauth/access_token"];
		
		signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
	}
	return self;
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
    [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}

//this method is overriden to add permissions (special Flickr quirk)
- (void)tokenAuthorize
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?oauth_token=%@&perms=%@", authorizeURL.absoluteString, requestToken.key, SHKCONFIG(flickrPermissions)]];
	
	SHKOAuthView *auth = [[SHKOAuthView alloc] initWithURL:url delegate:self];
	[[SHK currentHelper] showViewController:auth];
}

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKFlickrUserInfo];
    NSString *result = [userInfo findRecursivelyValueForKey:@"_content"];
    return result;
}

+ (void)logout {
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKFlickrUserInfo];
    [super logout];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
    
    NSArray *result = nil;
    switch (type) {
        case SHKShareTypeImage:
        case SHKShareTypeFile:
            result = @[[SHKFormFieldSettings label:SHKLocalizedString(@"Title")
                                               key:@"title"
                                              type:SHKFormFieldTypeText
                                             start:self.item.title],
                       [SHKFormFieldSettings label:SHKLocalizedString(@"Description")
                                               key:@"description"
                                              type:SHKFormFieldTypeText
                                             start:self.item.text],
                       [SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag")
                                               key:@"tags"
                                              type:SHKFormFieldTypeText
                                             start:[self.item.tags componentsJoinedByString:@", "]],
                       [SHKFormFieldSettings label:SHKLocalizedString(@"Is Public")
                                               key:@"is_public"
                                              type:SHKFormFieldTypeSwitch
                                             start:SHKFormFieldSwitchOn],
                       [SHKFormFieldSettings label:SHKLocalizedString(@"Is Friend")
                                               key:@"is_friend"
                                              type:SHKFormFieldTypeSwitch
                                             start:SHKFormFieldSwitchOn],
                       [SHKFormFieldSettings label:SHKLocalizedString(@"Is Family")
                                               key:@"is_family"
                                              type:SHKFormFieldTypeSwitch
                                             start:SHKFormFieldSwitchOn],
                       [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Post To Groups")
                                                           key:@"postgroup"
                                                         start:SHKLocalizedString(@"Select Group")
                                                   pickerTitle:SHKLocalizedString(@"Flickr Groups")
                                               selectedIndexes:nil
                                                 displayValues:nil
                                                    saveValues:nil
                                                 allowMultiple:YES
                                                  fetchFromWeb:YES
                                                      provider:self]];
            break;
        default:
            break;
    }
    return result;
 }

#pragma mark -
#pragma mark Implementation

- (BOOL)send
{
	if (![self validateItem])
		return NO;

    switch (self.item.shareType) {
        case SHKShareTypeUserInfo:
            self.quiet = YES;
            [self sendFlickrRequestMethod:@"flickr.test.login" parameters:nil];
            break;
        case SHKShareTypeImage:
        case SHKShareTypeFile:
            [self uploadPhoto];
            break;
        default:
            break;
    }

    [self sendDidStart];
    return YES;
}

- (OAAsynchronousDataFetcher *)sendFlickrRequestMethod:(NSString *)method parameters:(NSArray *)parameters {
    
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.flickr.com/services/rest/"]
                                                                    consumer:consumer
                                                                       token:accessToken
                                                                       realm:nil
                                                           signatureProvider:signatureProvider];
    [oRequest setHTTPMethod:@"POST"];
    
    OARequestParameter *formatParam = [[OARequestParameter alloc] initWithName:@"format" value:@"json"];
    OARequestParameter *noJSONCallbackParam = [[OARequestParameter alloc] initWithName:@"nojsoncallback" value:@"1"];
    OARequestParameter *methodParam = [[OARequestParameter alloc] initWithName:@"method" value:method];
    NSArray *completeParams = [@[formatParam, noJSONCallbackParam, methodParam] arrayByAddingObjectsFromArray:parameters];
    [oRequest setParameters:completeParams];
    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
    [fetcher start];
    return fetcher;
}

- (OAAsynchronousDataFetcher *)uploadPhoto {
    
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://up.flickr.com/services/upload/"]
                                                                    consumer:consumer
                                                                       token:accessToken
                                                                       realm:nil
                                                           signatureProvider:signatureProvider];
    [oRequest setHTTPMethod:@"POST"];
    
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:6];
    if ([self.item.title length] > 0) {
        [params addObject:[[OARequestParameter alloc] initWithName:@"title" value:self.item.title]];
    }
    if ([[self.item customValueForKey:@"description"] length] > 0) {
        [params addObject:[[OARequestParameter alloc] initWithName:@"description" value:[self.item customValueForKey:@"description"]]];
    }
    if ([self.item.tags count] > 0) {
        NSString *joinedTags = [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:nil tagSuffix:nil];
        [params addObject:[[OARequestParameter alloc] initWithName:@"tags" value:joinedTags]];
    }
    [params addObject:[[OARequestParameter alloc] initWithName:@"is_public" value:[self.item customValueForKey:@"is_public"]]];
    [params addObject:[[OARequestParameter alloc] initWithName:@"is_friend" value:[self.item customValueForKey:@"is_friend"]]];
    [params addObject:[[OARequestParameter alloc] initWithName:@"is_family" value:[self.item customValueForKey:@"is_family"]]];
    [oRequest setParameters:params];
    [oRequest prepare];
    
    if (self.item.shareType == SHKShareTypeImage) {
        
        NSData *imageData = UIImageJPEGRepresentation(self.item.image, .9);
        [oRequest attachFileWithParameterName:@"photo"
                                     filename:[self.item.title length] > 0 ? self.item.title:@"Photo"
                                  contentType:@"image/jpeg"
                                         data:imageData];
    } else {
        
        [oRequest attachFileWithParameterName:@"photo"
                                     filename:self.item.file.filename
                                  contentType:self.item.file.mimeType
                                         data:self.item.file.data];
    }
    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(uploadPhotoTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendTicket:didFailWithError:)];
    [fetcher start];
    return fetcher;
}

- (void)uploadPhotoTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
    
    if (ticket.didSucceed) {
        
        NSDictionary *response = [SHKXMLResponseParser dictionaryFromData:data];
        NSString* photoID = [response findRecursivelyValueForKey:@"photoid"];
        if (photoID) {
            
            [self sendDidFinish];
            self.quiet = YES; //now we are going to add uploaded photo to groups. Let's not bother user with indicators...Photo is uploaded anyway.
            NSArray *groupsArray = [[self.item customValueForKey:@"postgroup"] componentsSeparatedByString:@","];
            for (NSString *groupNSID in groupsArray) {
                
                NSArray *parameters = @[[[OARequestParameter alloc] initWithName:@"photo_id" value:photoID],
                                        [[OARequestParameter alloc] initWithName:@"group_id" value:groupNSID]];
                [self sendFlickrRequestMethod:@"flickr.groups.pools.add" parameters:parameters];
            }
        } else {
            
            NSString *code = [response findRecursivelyValueForKey:@"code"];
            if ([code isEqualToString:USER_REMOVED_ACCESS_CODE]) {
                [self shouldReloginWithPendingAction:SHKPendingSend];
            } else if ([code isEqualToString:USER_EXCEEDED_UPLOAD_LIMIT_CODE]) {
                [self sendDidFailWithError:[SHK error:[response findRecursivelyValueForKey:@"msg"]]];
            } else {
                [self sendShowSimpleErrorAlert];
            }
            SHKLog(@"Flickr upload ticket failed with error:%@", [[SHKXMLResponseParser dictionaryFromData:data] description]);
        }
            
    } else {
        
        [self sendShowSimpleErrorAlert];
        SHKLog(@"Flickr upload ticket failed with error:%@", [[SHKXMLResponseParser dictionaryFromData:data] description]);
    }
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
	if (ticket.didSucceed)
	{
		NSError *error = nil;
        NSMutableDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

        if ([response findRecursivelyValueForKey:@"_content"]) {
            
            //save userInfo
            [[NSUserDefaults standardUserDefaults] setObject:response forKey:kSHKFlickrUserInfo];
            [self sendDidFinish];
            
        } else if ([response findRecursivelyValueForKey:@"group"]) {
            
            [self hideActivityIndicator];
            
            //fill in OptionController with user's groups
            NSArray *groups = [response findRecursivelyValueForKey:@"group"];
            
            if ([groups count] > 0) {
                NSMutableArray *displayGroups = [[NSMutableArray alloc] initWithCapacity:[groups count]];
                NSMutableArray *saveGroups = [[NSMutableArray alloc] initWithCapacity:[groups count]];
                for (NSDictionary *group in groups) {
                    [displayGroups addObject:group[@"name"]];
                    [saveGroups addObject:group[@"nsid"]];
                }
                [self.curOptionController optionsEnumeratedDisplay:displayGroups save:saveGroups];
            } else {
                [self.curOptionController optionsEnumerationFailedWithError:nil];
            }
        } else {
            
            //error
            if ([response[@"code"] integerValue] == [USER_REMOVED_ACCESS_CODE integerValue]) {
                [self shouldReloginWithPendingAction:SHKPendingShare];
            } else {
                [self sendShowSimpleErrorAlert];
            }
            SHKLog(@"flickr got error%@", [response description]);
        }
	}
	
	else
	{
		[self sendShowSimpleErrorAlert];
        NSError *error;
        SHKLog(@"Flickr ticket did not succeed with error:%@", [[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error] description]);
	}
}
- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	if (self.curOptionController) {
        [self.curOptionController optionsEnumerationFailedWithError:error];
    } else {
        [self sendShowSimpleErrorAlert];
    }
}

#pragma mark - SHKFormOptionControllerOptionProvider delegate methods

- (void)SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController *)optionController {
    
    [self displayActivity:SHKLocalizedString(@"Loading...")];
	NSAssert(self.curOptionController == nil, @"there should never be more than one picker open.");
	self.curOptionController = optionController;
    self.getGroupsFetcher = [self sendFlickrRequestMethod:@"flickr.groups.pools.getGroups" parameters:nil];
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController *)optionController {
    
    [self hideActivityIndicator];
	NSAssert(self.curOptionController == optionController, @"there should never be more than one picker open.");
	[self.getGroupsFetcher cancel];
}

@end
