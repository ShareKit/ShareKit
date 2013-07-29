//
//  SHKFlickr
//  Flickr
//
//  Created by Neil Bostrom on 23/02/2011.
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
//
//  Flickr Library: ObjectiveFlickr - https://github.com/lukhnos/objectiveflickr


#import "SHKFlickr.h"

#import "SharersCommonHeaders.h"
#import "NSHTTPCookieStorage+DeleteForURL.h"

NSString *kFlickrAuthenticationURL = @"http://flickr.com/services/auth/";

NSString *kStoredAuthTokenKeyName = @"FlickrAuthToken";

NSString *kGetAuthTokenStep = @"kGetAuthTokenStep";
NSString *kCheckTokenStep = @"kCheckTokenStep";
NSString *kUploadImageStep = @"kUploadImageStep";
NSString *kSetImagePropertiesStep = @"kSetImagePropertiesStep";
NSString *kGetGroupsStep = @"kGetGroupsStep";
NSString *kPutInGroupsStep = @"kPutInGroupsStep";


@interface SHKFlickr();
-(void) optionsEnumerated:(NSArray*)options;
-(void) optionsEnumerationFailed:(NSError*)error;
-(void) postToNextGroup;

@property (nonatomic, strong) NSArray* fullOptionsData;
@property (nonatomic, strong) NSString *postedPhotoID;
@end


@implementation SHKFlickr

@synthesize flickrContext, flickrUserName, fullOptionsData, postedPhotoID;

+ (NSString *)sharerTitle
{
	return SHKLocalizedString(@"Flickr");
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShare
{
	return YES;
}

+ (BOOL)canAutoShare
{
	return NO;
}

- (BOOL)isAuthorized 
{
	return [self.flickrContext.authToken length];
}

- (OFFlickrAPIContext *)flickrContext
{
    if (!flickrContext) {
        flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey: SHKCONFIG(flickrConsumerKey) sharedSecret: SHKCONFIG(flickrSecretKey)];
		
        NSString *authToken = [SHK getAuthValueForKey: kStoredAuthTokenKeyName forSharer:[self sharerId]];
        if (authToken != nil) {
            flickrContext.authToken = authToken;
        }
    }
    
    return flickrContext;
}

- (OFFlickrAPIRequest *)flickrRequest
{
	if (!flickrRequest) {
		flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
		flickrRequest.delegate = self;	
        [[SHK currentHelper] keepSharerReference:self]; //released in request delegate methods, OFFFlickrAPIRequest does not retain its delegate
		flickrRequest.requestTimeoutInterval = 60.0;	
	}
	
	return flickrRequest;
}

+ (void)logout
{
    [SHK removeAuthValueForKey:kStoredAuthTokenKeyName forSharer:[self sharerId]];
    [NSHTTPCookieStorage deleteCookiesForURL:[NSURL URLWithString:kFlickrAuthenticationURL]];
}

- (void)authorizationFormShow 
{	
	NSURL *loginURL = [self.flickrContext loginURLFromFrobDictionary:nil requestedPermission:OFFlickrWritePermission];
	SHKOAuthView *auth = [[SHKOAuthView alloc] initWithURL:loginURL delegate:self];
	[[SHK currentHelper] showViewController:auth];	
}

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
    
    if([self.item shareType] == SHKShareTypeImage) {
        
		NSMutableArray *baseArray = [NSMutableArray arrayWithObjects:
									 [SHKFormFieldSettings label:SHKLocalizedString(@"Title")
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
                                                                        type:SHKFormFieldTypeOptionPicker
                                                                       start:SHKLocalizedString(@"Select Group")
                                                                 pickerTitle:SHKLocalizedString(@"Flickr Groups")
                                                             selectedIndexes:nil
                                                               displayValues:nil
                                                                  saveValues:nil
                                                               allowMultiple:YES
                                                                fetchFromWeb:YES
                                                                    provider:self],
                                     nil];
		return baseArray;
        
	} else {
		return [super shareFormFieldsForType:type];
	}
}

- (BOOL)send
{	
	if([self.item customValueForKey:@"is_public"] == nil)	// make sure we have all the data from the form.
		return NO;
	
	if (self.flickrUserName != nil) {
		[self sendPhoto];
	}
	else {
		
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
		
		[self flickrRequest].sessionInfo = kCheckTokenStep;
		[flickrRequest callAPIMethodWithGET:@"flickr.auth.checkToken" arguments:nil];
	}
	
	return YES;
}

- (NSData*) generateImageData
{
	return UIImageJPEGRepresentation(self.item.image, .9);
}

- (void)sendPhoto {
	
	[self sendDidStart];
	NSData *JPEGData = [self generateImageData];
	self.flickrRequest.sessionInfo = kUploadImageStep;
    
    NSString *tagString = [self tagStringJoinedBy:@" " allowedCharacters:[NSCharacterSet alphanumericCharacterSet] tagPrefix:nil tagSuffix:nil];
    
	NSString* descript = [self.item customValueForKey:@"description"] != nil ? [self.item customValueForKey:@"description"] : @"";
	NSString* titleVal = self.item.title != nil && ![self.item.title isEqualToString:@""] ? self.item.title : @"photo";
	NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys:
						  titleVal, @"title",
						  descript, @"description",
						  self.item.tags == nil ? @"" : tagString, @"tags",
						  [self.item customValueForKey:@"is_public"], @"is_public",
						  [self.item customValueForKey:@"is_friend"], @"is_friend",
						  [self.item customValueForKey:@"is_family"], @"is_family",
						  nil];
	[self.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:JPEGData] suggestedFilename:self.item.title MIMEType:@"image/jpeg" arguments:args];	
}

- (NSURL *)authorizeCallbackURL {
	return [NSURL URLWithString: SHKCONFIG(flickrCallbackUrl)];
}

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error {
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	if (!success)
	{
		[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
									 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while authorizing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] show];
	}
	else 
	{
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
		
		// query has the form of "&frob=", the rest is the frob
		NSString *frob = [queryParams objectForKey:@"frob"];
		
		[self flickrRequest].sessionInfo = kGetAuthTokenStep;
		[flickrRequest callAPIMethodWithGET:@"flickr.auth.getToken" arguments:[NSDictionary dictionaryWithObjectsAndKeys:frob, @"frob", nil]];
	}
	[self authDidFinish:success];
}

- (void)tokenAuthorizeCancelledView:(SHKOAuthView *)authView {
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
    [self authDidFinish:NO];
}

- (void)setAndStoreFlickrAuthToken:(NSString *)inAuthToken
{
	if (![inAuthToken length]) {
		
		[SHKFlickr logout];
	}
	else {
		
		self.flickrContext.authToken = inAuthToken;
		[SHK setAuthValue:inAuthToken forKey:kStoredAuthTokenKeyName forSharer:[self sharerId]];
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didCompleteWithResponse:(NSDictionary *)inResponseDictionary
{
	if(inRequest.sessionInfo == kGetGroupsStep){
		if ([inResponseDictionary objectForKey:@"groups"] != nil && 
			[[inResponseDictionary objectForKey:@"groups"] isKindOfClass:[NSDictionary class]] &&
			[[inResponseDictionary objectForKey:@"groups"] objectForKey:@"group"] != nil &&
			[[[inResponseDictionary objectForKey:@"groups"] objectForKey:@"group"] isKindOfClass:[NSArray class]]
			) 
		{
			self.fullOptionsData = [[inResponseDictionary objectForKey:@"groups"] objectForKey:@"group"];
			NSMutableArray* options = [NSMutableArray array];
			for (NSDictionary* option in self.fullOptionsData) {
				[options addObject:[option objectForKey:@"name"]];
			}
			[self optionsEnumerated:options];
		}else {
			NSError* err = [NSError errorWithDomain:OFFlickrAPIRequestErrorDomain code:OFFlickrAPIRequestFaultyXMLResponseError userInfo:nil];
			[self optionsEnumerationFailed:err];
		}
		return;
	}
	if(inRequest.sessionInfo == kPutInGroupsStep){
		[self postToNextGroup];
		return;
	}
	
	if (inRequest.sessionInfo == kUploadImageStep) {
		self.postedPhotoID = [[inResponseDictionary valueForKeyPath:@"photoid"] textContent];
		[self postToNextGroup];
		return;
	}else {
		[[SHKActivityIndicator currentIndicator] hide];
		
		if (inRequest.sessionInfo == kGetAuthTokenStep) {
			[self setAndStoreFlickrAuthToken:[[inResponseDictionary valueForKeyPath:@"auth.token"] textContent]];
			self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
			
			[self tryPendingAction];
		}
		else if (inRequest.sessionInfo == kCheckTokenStep) {
			self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
			
			[self sendPhoto];
		}
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
	if (inRequest.sessionInfo == kCheckTokenStep) {
        
        //if user revoked app permissions, we should relogin
        if ([inError.domain isEqualToString:@"com.flickr"] && inError.code == 98) {
            
            //after relogin silently share. User edited already.
            self.flickrContext.authToken = nil;
            [self shouldReloginWithPendingAction:SHKPendingSend];
        }
    }
    else if (inRequest.sessionInfo == kGetGroupsStep) {
        
        //if user revoked app permissions, we should relogin
        if ([inError.domain isEqualToString:@"com.flickr"] && inError.code == 98) {
            
            //after relogin continue editing
            self.flickrContext.authToken = nil;
            [self shouldReloginWithPendingAction:SHKPendingShare];
        }    
    }
    else {
        
        [self sendDidFailWithError:inError shouldRelogin:NO];
    }
    [[SHK currentHelper] removeSharerReference:self]; //see [self flickrRequest]
}

-(void) postToNextGroup
{
	bool finished = true;
	if(self.fullOptionsData != nil && [self.item customValueForKey:@"postgroup"] != nil){
		NSString *postGroups = [self.item customValueForKey:@"postgroup"];
		NSArray* indexes = [postGroups componentsSeparatedByString:@","];
		if(postGroupCurIndex < [indexes count]){
			NSString* postGroup = [indexes objectAtIndex:postGroupCurIndex++];
			NSString *groupID = nil;
			for (NSDictionary* group in self.fullOptionsData) {
				if([[group objectForKey:@"name"] isEqualToString:postGroup]){
					groupID = [group objectForKey:@"nsid"];
					break;
				}
			}
			if(groupID != nil){
				finished = false;
				flickrRequest.sessionInfo = kPutInGroupsStep;
				[flickrRequest callAPIMethodWithPOST:@"flickr.groups.pools.add" arguments:[NSDictionary dictionaryWithObjectsAndKeys:self.postedPhotoID, @"photo_id", groupID, @"group_id", nil]];        		        
			}
		}
	}
	if (finished) {
		[self sendDidFinish];
	}
}


-(void) optionsEnumerated:(NSArray*)options{
	NSAssert(self.curOptionController != nil, @"Any pending requests should have been canceled in SHKFormOptionControllerCancelEnumerateOptions");
	[self.curOptionController optionsEnumeratedDisplay:options save:nil];
}
-(void) optionsEnumerationFailed:(NSError*)error{
	NSAssert(self.curOptionController != nil, @"Any pending requests should have been canceled in SHKFormOptionControllerCancelEnumerateOptions");
	[self.curOptionController optionsEnumerationFailedWithError:error];
}

-(void) SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController*) optionController
{
	NSAssert(self.curOptionController == nil, @"there should never be more than one picker open.");
	self.curOptionController = optionController;
	self.flickrRequest.sessionInfo = kGetGroupsStep;
	[flickrRequest callAPIMethodWithGET:@"flickr.groups.pools.getGroups" arguments:[NSDictionary dictionary]];        		        
}
-(void) SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController*) optionController
{
	NSAssert(self.curOptionController == optionController, @"there should never be more than one picker open.");
	NSAssert(self.flickrRequest.sessionInfo == kGetGroupsStep, @"The active request should be kGetGroupsStep");
	[self.flickrRequest cancel];
}

@end
