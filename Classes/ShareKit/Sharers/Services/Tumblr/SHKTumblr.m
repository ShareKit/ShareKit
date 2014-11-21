//
//  SHKTumblr.m
//  ShareKit
//
//  Created by Vilem Kurz on 24. 2. 2013

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

#import "SHKTumblr.h"

#import "SharersCommonHeaders.h"
#import "SHKSession.h"

#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

#define MAX_SIZE_MB_PHOTO 10
#define MAX_SIZE_MB_AUDIO 10
#define MAX_SIZE_MB_VIDEO 100

NSString * const kSHKTumblrUserInfo = @"kSHKTumblrUserInfo";

@interface SHKTumblr ()

@property (nonatomic, strong) id getUserBlogsObserver;

@end

@implementation SHKTumblr

@synthesize getUserBlogsObserver;

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:getUserBlogsObserver];
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle { return SHKLocalizedString(@"Tumblr"); }

+ (BOOL)canShareURL { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareText { return YES; }
+ (BOOL)canShareFile:(SHKFile *)file {
    
    NSUInteger sizeInMB = file.size/1024/1024;
    
    BOOL result = NO;
    if ([file.mimeType hasPrefix:@"image/"]) {
        result = sizeInMB < MAX_SIZE_MB_PHOTO;
    } else if ([file.mimeType hasPrefix:@"audio/"]) {
        result = sizeInMB < MAX_SIZE_MB_AUDIO;
    } else if ([file.mimeType hasPrefix:@"video/"]) {
        result = sizeInMB < MAX_SIZE_MB_VIDEO;
    }
    return result;
}
+ (BOOL)canGetUserInfo { return YES; }
+ (BOOL)canAutoShare { return NO; }

#pragma mark -
#pragma mark Authentication

- (id)init
{
	if (self = [super init])
	{		
		self.consumerKey = SHKCONFIG(tumblrConsumerKey);;		
		self.secretKey = SHKCONFIG(tumblrSecret);
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKCONFIG(tumblrCallbackUrl)];
		
	    self.requestURL = [NSURL URLWithString:@"https://www.tumblr.com/oauth/request_token"];
	    self.authorizeURL = [NSURL URLWithString:@"https://www.tumblr.com/oauth/authorize"];
	    self.accessURL = [NSURL URLWithString:@"https://www.tumblr.com/oauth/access_token"];
		
		self.signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];
	}	
	return self;
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{
	[oRequest setOAuthParameterName:@"oauth_verifier" withValue:[self.authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
}

+ (void)logout {
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kSHKTumblrUserInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
	[super logout];
}

+ (NSString *)username {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSHKTumblrUserInfo];
    NSString *result = userInfo[@"response"][@"user"][@"name"];
    return result;
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
    if (type == SHKShareTypeUserInfo) return nil;
    
    //if there is user info saved already in defaults, show the first blog as default option, otherwise user must choose one.
    NSArray *userBlogURLs = [self userBlogURLs];
    NSString *defaultBlogURL = nil;
    NSMutableIndexSet *defaultPickedIndex = [[NSMutableIndexSet alloc] init];
    NSMutableArray *defaultItemsList = [NSMutableArray arrayWithCapacity:0];
    if ([userBlogURLs count] > 0) {
        defaultBlogURL = userBlogURLs[0];
        [defaultPickedIndex addIndex:0];
        [defaultItemsList addObject:defaultBlogURL];
    }
    
    SHKFormFieldOptionPickerSettings *blogField = [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Blog")
                                                                                      key:@"blog"
                                                                                    start:SHKLocalizedString(@"Select blog")
                                                                              pickerTitle:SHKLocalizedString(@"Choose blog")
                                                                          selectedIndexes:defaultPickedIndex
                                                                            displayValues:userBlogURLs
                                                                               saveValues:nil
                                                                            allowMultiple:NO
                                                                             fetchFromWeb:YES
                                                                                 provider:self];
    blogField.validationBlock = ^ (SHKFormFieldOptionPickerSettings *formFieldSettings) {
        
        BOOL result = [formFieldSettings valueToSave].length > 0;
        return result;
    };
    
    SHKFormFieldSettings *tagsField = [SHKFormFieldSettings label:SHKLocalizedString(@"Tag, tag")
                                                              key:@"tags"
                                                             type:SHKFormFieldTypeText
                                                            start:[self.item.tags componentsJoinedByString:@", "]];
    
    SHKFormFieldOptionPickerSettings *publishField = [SHKFormFieldOptionPickerSettings label:SHKLocalizedString(@"Publish")
                                                                                         key:@"publish"
                                                                                       start:SHKLocalizedString(@"Publish now")
                                                                                 pickerTitle:SHKLocalizedString(@"Publish type")
                                                                             selectedIndexes:[[NSMutableIndexSet alloc] initWithIndex:0]
                                                                               displayValues:@[SHKLocalizedString(@"Publish now"), SHKLocalizedString(@"Draft"),
                                                      SHKLocalizedString(@"Add to queue"), SHKLocalizedString(@"Private")]
                                                                                  saveValues:@[@"published", @"draft", @"queue", @"private"]
                                                                               allowMultiple:NO
                                                                                fetchFromWeb:NO
                                                                                    provider:nil];
    NSMutableArray *result = nil;
    switch (type) {
        case SHKShareTypeText:
        {
            SHKFormFieldSettings *bodyField = [SHKFormFieldSettings label:SHKLocalizedString(@"Body")
                                                                      key:@"text"
                                                                     type:SHKFormFieldTypeText
                                                                    start:self.item.text];
            result = [NSMutableArray arrayWithObjects:blogField, [self titleFieldWithLabel:SHKLocalizedString(@"Title")], bodyField, tagsField, publishField, nil];
            break;
        }
        case SHKShareTypeURL:
        {
            SHKFormFieldSettings *descriptionField = [SHKFormFieldSettings label:SHKLocalizedString(@"Description")
                                                                             key:@"text"
                                                                            type:SHKFormFieldTypeText
                                                                           start:self.item.text];
            result = [NSMutableArray arrayWithObjects:blogField, [self titleFieldWithLabel:SHKLocalizedString(@"Title")], descriptionField, tagsField, publishField, nil];
            break;
        }
        case SHKShareTypeImage:
        case SHKShareTypeFile:
        {
            SHKFormFieldSettings *attachmentCaptionField = [SHKFormFieldLargeTextSettings label:SHKLocalizedString(@"Caption") key:@"title" start:self.item.title item:self.item];
            result = [NSMutableArray arrayWithObjects:attachmentCaptionField, tagsField, blogField, publishField, nil];
        }
        default:
            break;
    }
    return result;
}

- (SHKFormFieldSettings *)titleFieldWithLabel:(NSString *)label {
    
    return [SHKFormFieldSettings label:label key:@"title" type:SHKFormFieldTypeText start:self.item.title];
}

#pragma mark -
#pragma mark Implementation

- (BOOL)validateItem
{
    if (self.item.shareType == SHKShareTypeUserInfo) return [super validateItem];
	
    NSString *blog = [self.item customValueForKey:@"blog"];
    BOOL isBlogFilled = ![blog isEqualToString:@""] && ![blog isEqualToString:@"-1"] && blog != nil;
    BOOL itemValid = isBlogFilled && [super validateItem];
    
	return itemValid;
}

// Send the share item to the server
- (BOOL)send
{	
	if (![self validateItem])
		return NO;
	
    OAMutableURLRequest *oRequest = nil;
    NSMutableArray *params = [@[] mutableCopy];
    
    switch (self.item.shareType) {
            
        case SHKShareTypeUserInfo:
        {
            [self setQuiet:YES];
            oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.tumblr.com/v2/user/info"]
                                                                          consumer:self.consumer // this is a consumer object already made available to us
                                                                             token:self.accessToken // this is our accessToken already made available to us
                                                                             realm:nil
                                                                 signatureProvider:self.signatureProvider];
            [oRequest setHTTPMethod:@"GET"];
            [self sendRequest:oRequest];
            return YES;
            break;
        }
        case SHKShareTypeText:
        {
            oRequest = [self setupPostRequest];
            
            OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"text"];
            OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title" value:self.item.title];
            OARequestParameter *bodyParam = [[OARequestParameter alloc] initWithName:@"body" value:self.item.text];
            [params addObjectsFromArray:@[typeParam, titleParam, bodyParam]];
            break;
        }
        case SHKShareTypeURL:
        {
            oRequest = [self setupPostRequest];
            
            switch (self.item.URLContentType) {
                case SHKURLContentTypeVideo:
                {
                    OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"video"];
                    OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"caption" value:self.item.title];
                    OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"embed" value:[self.item.URL absoluteString]];
                    [params addObjectsFromArray:@[typeParam, titleParam, urlParam]];
                    break;
                }
                case SHKURLContentTypeAudio:
                {
                    OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"audio"];
                    OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"caption" value:self.item.title];
                    OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"external_url" value:[self.item.URL absoluteString]];
                    [params addObjectsFromArray:@[typeParam, titleParam, urlParam]];
                    break;
                }
                case SHKURLContentTypeImage:
                {
                    OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"photo"];
                    OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"caption" value:self.item.title];
                    OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"source" value:[self.item.URL absoluteString]];
                    [params addObjectsFromArray:@[typeParam, titleParam, urlParam]];
                    break;
                }
                default:
                {
                    OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:@"link"];
                    OARequestParameter *titleParam = [[OARequestParameter alloc] initWithName:@"title" value:self.item.title];
                    OARequestParameter *urlParam = [[OARequestParameter alloc] initWithName:@"url" value:[self.item.URL absoluteString]];
                    [params addObjectsFromArray:@[typeParam, titleParam, urlParam]];
                    
                    if (self.item.text) {
                        OARequestParameter *descriptionParam = [[OARequestParameter alloc] initWithName:@"description" value:self.item.text];
                        [params addObject:descriptionParam];
                    }
                    break;
                }
            }
            break;
        }
        case SHKShareTypeImage:
        case SHKShareTypeFile:
        {
            oRequest = [self setupPostRequest];
            
            NSString *typeValue = nil;
            if (self.item.image||[self.item.file.mimeType hasPrefix:@"image/"]) {
                typeValue = @"photo";
            } else if ([self.item.file.mimeType hasPrefix:@"video/"]) {
                typeValue = @"video";
            } else if ([self.item.file.mimeType hasPrefix:@"audio/"]) {
                typeValue = @"audio";
            }
            OARequestParameter *typeParam = [[OARequestParameter alloc] initWithName:@"type" value:typeValue];
            OARequestParameter *captionParam = [[OARequestParameter alloc] initWithName:@"caption" value:self.item.title];
            
            //Setup the request...
            [params addObjectsFromArray:@[typeParam, captionParam]];
            
            break;
        }
        default:
            return NO;
            break;
    }
    
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@","] invertedSet];
	NSString *tags = [self tagStringJoinedBy:@"," allowedCharacters:allowedCharacters tagPrefix:nil tagSuffix:nil];
    OARequestParameter *tagsParam = [[OARequestParameter alloc] initWithName:@"tags" value:tags];
    OARequestParameter *publishParam = [[OARequestParameter alloc] initWithName:@"state" value:[self.item customValueForKey:@"publish"]];
    [params addObjectsFromArray:@[tagsParam, publishParam]];
    [oRequest setParameters:params];
    
    BOOL hasDataContent = self.item.image || self.item.file;
    if (hasDataContent) {
        
        if (self.item.image && !self.item.file) {
            [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:1];
        }
        
        [oRequest attachFile:self.item.file withParameterName:@"data"];
    }
    
    [self sendRequest:oRequest];
    
    // Notify delegate
    [self sendDidStart];
    
    return YES;
}

- (OAMutableURLRequest *)setupPostRequest {
    
    NSString *urlString = [[NSString alloc] initWithFormat:@"http://api.tumblr.com/v2/blog/%@/post", [self.item customValueForKey:@"blog"]];
    OAMutableURLRequest *result = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]
                                               consumer:self.consumer // this is a consumer object already made available to us
                                                  token:self.accessToken // this is our accessToken already made available to us
                                                  realm:nil
                                      signatureProvider:self.signatureProvider];
    [result setHTTPMethod:@"POST"];
    return result;
}

- (void)sendRequest:(OAMutableURLRequest *)finalizedRequest {
    
    BOOL canUseNSURLSession = NSClassFromString(@"NSURLSession") != nil;
    if (self.item.file && canUseNSURLSession) {
        
        __weak typeof(self) weakSelf = self;
        self.networkSession = [SHKSession startSessionWithRequest:finalizedRequest delegate:self completion:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (error.code == -999) {
                [weakSelf sendDidCancel];
            } else if (!error) {
                [weakSelf sendDidFinishWithData:data response:(NSHTTPURLResponse *)response];
            } else {
                [weakSelf sendTicket:nil didFailWithError:error];
            }
            [[SHK currentHelper] removeSharerReference:self];
        }];
        [[SHK currentHelper] keepSharerReference:self];
        
    } else {

        OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:finalizedRequest
                                                                                              delegate:self
                                                                                     didFinishSelector:@selector(sendTicket:didFinishWithData:)
                                                                                       didFailSelector:@selector(sendTicket:didFailWithError:)];
        [fetcher start];
    }
}

- (void)sendTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{	
    [self sendDidFinishWithData:data response:ticket.response];
}

- (void)sendDidFinishWithData:(NSData *)data response:(NSHTTPURLResponse *)response {
    
    BOOL success = response.statusCode < 400;
    
    if (success) {
		
		switch (self.item.shareType) {
            case SHKShareTypeUserInfo:
            {
                NSError *error = nil;
                NSMutableDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                
                if (error) {
                    SHKLog(@"Error when parsing json user info request:%@", [error description]);
                }
                
                [userInfo convertNSNullsToEmptyStrings];
                [[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:kSHKTumblrUserInfo];
                
                break;
            }
            default:
                break;
        }
        
		[self sendDidFinish];
		
	} else {
		
        if (response.statusCode == 401) {
            
            //user revoked acces, ask access again
            [self shouldReloginWithPendingAction:SHKPendingSend];
            
        } else {
            
            SHKLog(@"Tumblr send finished with error:%@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
            [self sendShowSimpleErrorAlert];
        }
	}
}

- (void)sendTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	SHKLog(@"Tumblr send failed with error:%@", [error description]);
    [self sendShowSimpleErrorAlert];
}

#pragma mark - SHKFormOptionControllerOptionProvider delegate methods

- (void)SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController *)optionController {
    
    NSAssert(self.curOptionController == nil, @"there should never be more than one picker open.");
	self.curOptionController = optionController;
    
    [self displayActivity:SHKLocalizedString(@"Loading...")];
    
    SHKTumblr *infoSharer = [SHKTumblr getUserInfo];
    
    __weak SHKTumblr *weakSelf = self;
    self.getUserBlogsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:SHKSendDidFinishNotification
                                                      object:infoSharer
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *notification) {
                                                      
                                                      [weakSelf hideActivityIndicator];
                                                      
                                                      NSArray *userBlogURLs = [weakSelf userBlogURLs];
                                                      [weakSelf blogsEnumerated:userBlogURLs];
                                                      
                                                      [[NSNotificationCenter defaultCenter] removeObserver:weakSelf.getUserBlogsObserver];
                                                      weakSelf.getUserBlogsObserver = nil;
                                                  }];
}

- (void)SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController *)optionController
{
    [self hideActivityIndicator];
    [[NSNotificationCenter defaultCenter] removeObserver:self.getUserBlogsObserver];
    self.getUserBlogsObserver = nil;
    NSAssert(self.curOptionController == optionController, @"there should never be more than one picker open.");
}

#pragma mark - 

- (void)blogsEnumerated:(NSArray *)blogs{
    
	NSAssert(self.curOptionController != nil, @"Any pending requests should have been canceled in SHKFormOptionControllerCancelEnumerateOptions");
	[self.curOptionController optionsEnumeratedDisplay:blogs save:nil];
}

- (NSArray *)userBlogURLs {
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kSHKTumblrUserInfo];
    NSArray *usersBlogs = [[[userInfo objectForKey:@"response"] objectForKey:@"user"] objectForKey:@"blogs"];
    NSMutableArray *result = [@[] mutableCopy];
    for (NSDictionary *blog in usersBlogs) {
        NSURL *blogURL = [NSURL URLWithString:[blog objectForKey:@"url"]];
        [result addObject:blogURL.host];
    }
    return result;
}

@end
