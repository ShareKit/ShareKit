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
#import "SHKConfiguration.h"

NSString *kStoredAuthTokenKeyName = @"FlickrAuthToken";

NSString *kGetAuthTokenStep = @"kGetAuthTokenStep";
NSString *kCheckTokenStep = @"kCheckTokenStep";
NSString *kUploadImageStep = @"kUploadImageStep";
NSString *kSetImagePropertiesStep = @"kSetImagePropertiesStep";

@implementation SHKFlickr

@synthesize flickrContext, flickrUserName;

+ (NSString *)sharerTitle
{
	return @"Flickr";
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShare
{
	return YES;
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
		flickrRequest.requestTimeoutInterval = 60.0;	
	}
	
	return flickrRequest;
}

+ (void)logout
{
	[SHK removeAuthValueForKey:kStoredAuthTokenKeyName forSharer:[self sharerId]];
}

- (void)authorizationFormShow 
{	
	NSURL *loginURL = [self.flickrContext loginURLFromFrobDictionary:nil requestedPermission:OFFlickrWritePermission];
	SHKOAuthView *auth = [[SHKOAuthView alloc] initWithURL:loginURL delegate:self];
	[[SHK currentHelper] showViewController:auth];	
	[auth release];
}

- (NSArray *)shareFormFieldsForType:(SHKShareType)type{
    if([self.item shareType] == SHKShareTypeImage){
		NSMutableArray *baseArray = [NSMutableArray arrayWithObjects:
									 [SHKFormFieldSettings label:SHKLocalizedString(@"Title")
															 key:@"title"
															type:SHKFormFieldTypeText
														   start:nil],
									 [SHKFormFieldSettings label:SHKLocalizedString(@"Description")
															 key:@"description"
															type:SHKFormFieldTypeText
														   start:nil],
									 [SHKFormFieldSettings label:SHKLocalizedString(@"Tag (space) Tag")
															 key:@"tags"
															type:SHKFormFieldTypeText
														   start:nil],
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
									 nil
									 ];
		
		return baseArray;
	}else {
		return [super shareFormFieldsForType:type];
	}
	
}

- (BOOL)send
{	
	if([item customValueForKey:@"is_public"] == nil)	// make sure we have all the data from the form.
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

- (void)sendPhoto {
	
	[self sendDidStart];
	
	NSData *JPEGData = UIImageJPEGRepresentation(item.image, 1.0);
	
	self.flickrRequest.sessionInfo = kUploadImageStep;
	NSString* descript = [item customValueForKey:@"description"] != nil ? [item customValueForKey:@"description"] : @"";
	NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys:
						  item.title, @"title",
						  descript, @"description",
						  item.tags, @"tags",
						  [item customValueForKey:@"is_public"], @"is_public",
						  [item customValueForKey:@"is_friend"], @"is_friend",
						  [item customValueForKey:@"is_family"], @"is_family",
						  nil];
	[self.flickrRequest uploadImageStream:[NSInputStream inputStreamWithData:JPEGData] suggestedFilename:item.title MIMEType:@"image/jpeg" arguments:args];	
}

- (NSURL *)authorizeCallbackURL {
	return [NSURL URLWithString: SHKCONFIG(flickrCallbackUrl)];
}

- (void)tokenAuthorizeView:(SHKOAuthView *)authView didFinishWithSuccess:(BOOL)success queryParams:(NSMutableDictionary *)queryParams error:(NSError *)error {
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
	
	if (!success)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Authorize Error")
									 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while authorizing")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
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
#if 0
	if (inRequest.sessionInfo == kUploadImageStep) {
		
        NSString *photoID = [[inResponseDictionary valueForKeyPath:@"photoid"] textContent];
		
        flickrRequest.sessionInfo = kSetImagePropertiesStep;
        [flickrRequest callAPIMethodWithPOST:@"flickr.photos.setMeta" arguments:[NSDictionary dictionaryWithObjectsAndKeys:photoID, @"photo_id", item.title, @"title", nil, @"description", nil]];        		        
	}
	else if (inRequest.sessionInfo == kSetImagePropertiesStep) {
		
		[self sendDidFinish];
	}
#else
	if (inRequest.sessionInfo == kUploadImageStep) {
		// best I can tell we can set all the props during upload.
		[self sendDidFinish];
	}
#endif
	else {
		[[SHKActivityIndicator currentIndicator] hide];
		
		if (inRequest.sessionInfo == kGetAuthTokenStep) {
			[self setAndStoreFlickrAuthToken:[[inResponseDictionary valueForKeyPath:@"auth.token"] textContent]];
			self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
			
			[self share];
		}
		else if (inRequest.sessionInfo == kCheckTokenStep) {
			self.flickrUserName = [inResponseDictionary valueForKeyPath:@"auth.user.username"];
			
			[self sendPhoto];
		}
	}
}

- (void)flickrAPIRequest:(OFFlickrAPIRequest *)inRequest didFailWithError:(NSError *)inError
{
	if (inRequest.sessionInfo == kGetAuthTokenStep) {
	}
	else if (inRequest.sessionInfo == kCheckTokenStep) {
		[self setAndStoreFlickrAuthToken:nil];
	}
	
	[self sharer: self failedWithError: inError shouldRelogin: NO];
}

- (void)dealloc
{
    [flickrContext release];
	[flickrRequest release];
	[flickrUserName release];
    [super dealloc];
}

@end
