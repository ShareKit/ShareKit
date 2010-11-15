//
//  SHKEvernote
//  ShareKit Evernote Additions
//
//  Created by Atsushi Nagase on 8/28/10.
//  Copyright 2010 LittleApps Inc. All rights reserved.
//

#import "SHKEvernote.h"
#import "THTTPClient.h"
#import "TBinaryProtocol.h"
#import "NSData+md5.h"

@implementation SHKEvernoteItem
@synthesize note;

- (void)dealloc {
	[note release];
	[super dealloc];	
}


@end

@interface SHKEvernote(private)

- (void)authFinished:(BOOL)success;
- (void)sendFinished:(BOOL)success;

@end


@implementation SHKEvernote


#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle { return @"Evernote"; }
+ (BOOL)canShareURL   { return YES; }
+ (BOOL)canShareImage { return YES; }
+ (BOOL)canShareText  { return YES; }
+ (BOOL)canShareFile  { return YES; }
+ (BOOL)requiresAuthentication { return YES; }


#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare {	return YES; }

#pragma mark -
#pragma mark Authentication

// Return the form fields required to authenticate the user with the service
+ (NSArray *)authorizationFormFields 
{
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:@"Username" key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:@"Password" key:@"password" type:SHKFormFieldTypePassword start:nil],			
			nil];
}

+ (NSString *)authorizationFormCaption 
{
	return SHKLocalizedString(@"Create a free account at %@", @"Evernote.com");
}

- (void)authorizationFormValidate:(SHKFormController *)form 
{
	// Display an activity indicator
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
	
	// Authorize the user through the server
	self.pendingForm = form;
	[NSThread detachNewThreadSelector:@selector(_authorizationFormValidate:) toTarget:self withObject:[form formValues]];
}

- (void)_authorizationFormValidate:(NSDictionary *)args 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL success = NO;
	@try {
		EDAMAuthenticationResult *authResult = [self getAuthenticationResultForUsername:[args valueForKey:@"username"] password:[args valueForKey:@"password"]];
		success = authResult&&[authResult userIsSet]&&[authResult authenticationTokenIsSet];
	}
	@catch (NSException * e) {
		SHKLog(@"Caught %@: %@ %@", [e name], [e reason],e);
	}	
	[self performSelectorOnMainThread:@selector(_authFinished:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:success?@"1":@"0",@"success",nil] waitUntilDone:YES];
    [pool release];
}

- (EDAMAuthenticationResult *)getAuthenticationResultForUsername:(NSString *)username password:(NSString *)password 
{
	THTTPClient *userStoreHTTPClient = [[[THTTPClient alloc] initWithURL:[NSURL URLWithString:SHKEvernoteUserStoreURL]] autorelease];
	TBinaryProtocol *userStoreProtocol = [[[TBinaryProtocol alloc] initWithTransport:userStoreHTTPClient] autorelease];
	EDAMUserStoreClient *userStore = [[[EDAMUserStoreClient alloc] initWithProtocol:userStoreProtocol] autorelease];

	BOOL versionOK = [userStore checkVersion:@"ShrareKit EDMA" :[EDAMUserStoreConstants EDAM_VERSION_MAJOR] :[EDAMUserStoreConstants EDAM_VERSION_MINOR]];
	if(!versionOK) 
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"EDMA Error")
									 message:SHKLocalizedString(@"EDMA Version is too old.")
									delegate:nil 
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return nil;
	}
	return [userStore authenticate :username :password :SHKEvernoteConsumerKey :SHKEvernoteSecretKey];
}

- (void)_authFinished:(NSDictionary *)args 
{
	[self authFinished:[[args valueForKey:@"success"] isEqualToString:@"1"]];
}

- (void)authFinished:(BOOL)success 
{
	[[SHKActivityIndicator currentIndicator] hide];
	if(!success)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Login Error") message:SHKLocalizedString(@"Your username and password did not match") delegate:nil cancelButtonTitle:SHKLocalizedString(@"Close") otherButtonTitles:nil] autorelease] show];
		return;
	}
	else
		[pendingForm saveForm];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type 
{
	return [NSArray arrayWithObjects:
	 [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:item.title],
	 //[SHKFormFieldSettings label:SHKLocalizedString(@"Memo")  key:@"text" type:SHKFormFieldTypeText start:item.text],
	 [SHKFormFieldSettings label:SHKLocalizedString(@"Tags")  key:@"tags" type:SHKFormFieldTypeText start:item.tags],
	 nil];
}

- (void)shareFormValidate:(SHKCustomFormController *)form 
{	
	[form saveForm];
}

#pragma mark -
#pragma mark Implementation

- (BOOL)validateItem {  return [super validateItem]; }

- (EDAMNotebook *)defaultNoteBookFromNoteStore:(EDAMNoteStoreClient *)noteStore authToken:(NSString *)authToken {
	NSArray *notebooks = [noteStore listNotebooks:authToken];
	for(int i = 0; i < [notebooks count]; i++) {
		EDAMNotebook *notebook = (EDAMNotebook*)[notebooks objectAtIndex:i];
		if([notebook defaultNotebook]) return notebook;
	}
	return nil;
}

- (BOOL)send {
	if (![self validateItem])
		return NO;
	[self sendDidStart];
	[NSThread detachNewThreadSelector:@selector(_send) toTarget:self withObject:nil];
	return YES;
}

- (void)_send {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL success = NO;
	NSString *authToken;
  NSURL *noteStoreURL;
	NSString *errorMessage = nil;
	BOOL shouldRelogin = NO;
	@try {
  	////////////////////////////////////////////////
  	// Authentication
  	////////////////////////////////////////////////
		EDAMAuthenticationResult *authResult = [self getAuthenticationResultForUsername:[self getAuthValueForKey:@"username"] password:[self getAuthValueForKey:@"password"]];
    EDAMUser *user = [authResult user];
    authToken    = [authResult authenticationToken];
    noteStoreURL = [NSURL URLWithString:[SHKEvernoteNetStoreURLBase stringByAppendingString:[user shardId]]];

  	////////////////////////////////////////////////
    // Make clients
  	////////////////////////////////////////////////
    THTTPClient *noteStoreHTTPClient = [[[THTTPClient alloc] initWithURL:noteStoreURL] autorelease];
    TBinaryProtocol *noteStoreProtocol = [[[TBinaryProtocol alloc] initWithTransport:noteStoreHTTPClient] autorelease];
    EDAMNoteStoreClient *noteStore = [[[EDAMNoteStoreClient alloc] initWithProtocol:noteStoreProtocol] autorelease];

  	////////////////////////////////////////////////
    // Make EDAMNote contents
  	////////////////////////////////////////////////
		SHKEvernoteItem *enItem = nil;
		NSMutableArray *resources = nil;
		EDAMNote *note = nil;
		if([item isKindOfClass:[SHKEvernoteItem class]]) {
			enItem = (SHKEvernoteItem *)item;
			note = enItem.note;
			resources = [note.resources mutableCopy];
		}

		if(!resources)
    	resources = [[NSMutableArray alloc] init];
		if(!note)
    	note = [[[EDAMNote alloc] init] autorelease];

		
		EDAMNoteAttributes *atr = [note attributesIsSet] ? [note.attributes retain] : [[EDAMNoteAttributes alloc] init];

		if(![atr sourceURLIsSet]&&enItem.URL)
    	[atr setSourceURL:[enItem.URL absoluteString]];
		if(![note notebookGuidIsSet])
    	[note setNotebookGuid:[[self defaultNoteBookFromNoteStore:noteStore authToken:authToken] guid]];

		note.title = item.title.length > 0 ?
    	item.title :
      ( [note titleIsSet] ?
            note.title :
            SHKLocalizedString(@"Untitled") );

		if(![note tagNamesIsSet]&&item.tags)
    	[note setTagNames:[item.tags componentsSeparatedByString:@" "]];

		if(![note contentIsSet]) {
			NSMutableString* contentStr = [[NSMutableString alloc] initWithString:kENMLPrefix];
      NSString * strURL = [item.URL absoluteString];

      if(strURL.length>0) {
        if(item.title.length>0)
        	[contentStr appendFormat:@"<h1><a href=\"%@\">%@</a></h1>",strURL,item.title];
      	[contentStr appendFormat:@"<p><a href=\"%@\">%@</a></p>",strURL,strURL];
        atr.sourceURL = strURL;
      } else if(item.title.length>0)
        [contentStr appendFormat:@"<h1>%@</h1>",item.title];

			if(item.text.length>0 )
      	[contentStr appendFormat:@"<p>%@</p>",item.text];

			if(item.image) {
				EDAMResource *img = [[[EDAMResource alloc] init] autorelease];
				NSData *rawimg = UIImageJPEGRepresentation(item.image, 0.6);
				EDAMData *imgd = [[[EDAMData alloc] initWithBodyHash:rawimg size:[rawimg length] body:rawimg] autorelease];
				[img setData:imgd];
				[img setRecognition:imgd];
				[img setMime:@"image/jpeg"];
				[resources addObject:img];
				[contentStr appendString:[NSString stringWithFormat:@"<p>%@</p>",[self enMediaTagWithResource:img width:item.image.size.width height:item.image.size.height]]];
			}

			if(item.data) {
				EDAMResource *file = [[[EDAMResource alloc] init] autorelease];	
				EDAMData *filed = [[[EDAMData alloc] initWithBodyHash:item.data size:[item.data length] body:item.data] autorelease];
				[file setData:filed];
				[file setRecognition:filed];
				[file setMime:item.mimeType];
				[resources addObject:file];
				[contentStr appendString:[NSString stringWithFormat:@"<p>%@</p>",[self enMediaTagWithResource:file width:0 height:0]]];
			}
			[contentStr appendString:kENMLSuffix];
			[note setContent:contentStr];
			[contentStr release];
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
						EDAMData *imgd = [[[EDAMData alloc] initWithBodyHash:rawimg size:[rawimg length] body:rawimg] autorelease];
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
		[resources release];
		[atr release];
    [note setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
    EDAMNote *createdNote = [noteStore createNote:authToken :note];
    if (createdNote != NULL) {
      SHKLog(@"Created note: %@", [createdNote title]);
			success = YES;
    }
  }
  @catch (EDAMUserException * e) 
	{
		SHKLog(@"%@",e);
		
		NSString *errorName;		
		switch (e.errorCode) 
		{
			case EDAMErrorCode_BAD_DATA_FORMAT:
				errorName = @"Invalid format";
				break;
			case EDAMErrorCode_PERMISSION_DENIED:
				errorName = @"Permission Denied";
				break;
			case EDAMErrorCode_INTERNAL_ERROR:
				errorName = @"Internal Evernote Error";
				break;
			case EDAMErrorCode_DATA_REQUIRED:
				errorName = @"Data Required";
				break;
			case EDAMErrorCode_QUOTA_REACHED:
				errorName = @"Quota Reached";
				break;
			case EDAMErrorCode_INVALID_AUTH:
				errorName = @"Invalid Auth";
				shouldRelogin = YES;
				break;
			case EDAMErrorCode_AUTH_EXPIRED:
				errorName = @"Auth Expired";
				shouldRelogin = YES;
				break;
			case EDAMErrorCode_DATA_CONFLICT:
				errorName = @"Data Conflict";
				break;
			default:
				errorName = @"Unknown error from Evernote";
				break;
		}
		
		errorMessage = [NSString stringWithFormat:@"Evernote Error on %@: %@", e.parameter, errorName];
	}
	[self performSelectorOnMainThread:@selector(_sendFinished:)
						   withObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   success?@"1":@"0",@"success",
									   errorMessage==nil?@"":errorMessage,@"errorMessage",
									   shouldRelogin?@"1":@"0",@"shouldRelogin",
									   nil] waitUntilDone:YES];
	[pool release];
}

- (NSString *)enMediaTagWithResource:(EDAMResource *)src width:(CGFloat)width height:(CGFloat)height {
	NSString *sizeAtr = width > 0 && height > 0 ? [NSString stringWithFormat:@"height=\"%.0f\" width=\"%.0f\" ",height,width]:@"";
	return [NSString stringWithFormat:@"<en-media type=\"%@\" %@hash=\"%@\"/>",src.mime,sizeAtr,[src.data.body md5]];
}

- (void)_sendFinished:(NSDictionary *)args 
{
	if (![[args valueForKey:@"success"] isEqualToString:@"1"])
	{
		if ([[args valueForKey:@"shouldRelogin"] isEqualToString:@"1"])
		{
			[self sendDidFailShouldRelogin];
			return;
		}
		
		[self sendDidFailWithError:[SHK error:[args valueForKey:@"errorMessage"]]];
		return;
	}
	
	[self sendDidFinish];
}


- (void)sendFinished:(BOOL)success {	
	if (success) {
		[self sendDidFinish];
	} else {
		[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was a problem sharing with Evernote")] shouldRelogin:NO];
	}
}

@end
