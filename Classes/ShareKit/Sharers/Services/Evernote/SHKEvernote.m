//  Created by Atsushi Nagase on 8/27/10.

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
+ (NSArray *)authorizationFormFields {
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:@"Username" key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:@"Password" key:@"password" type:SHKFormFieldTypePassword start:nil],			
			nil];
}

+ (NSString *)authorizationFormCaption {
	return SHKLocalizedString(@"Create a free account at %@", @"www.evernote.com/Registration.action");
}

- (EDAMAuthenticationResult *)getAuthenticationResultForUsername:(NSString *)username password:(NSString *)password {
  THTTPClient *userStoreHTTPClient = [[[THTTPClient alloc] initWithURL:[NSURL URLWithString:kEvernoteUserStoreURL]] autorelease];
  TBinaryProtocol *userStoreProtocol = [[[TBinaryProtocol alloc] initWithTransport:userStoreHTTPClient] autorelease];
  EDAMUserStoreClient *userStore = [[[EDAMUserStoreClient alloc] initWithProtocol:userStoreProtocol] autorelease];
	BOOL versionOK = [userStore checkVersion:@"ShrareKit EDMA" :[EDAMUserStoreConstants EDAM_VERSION_MAJOR] :[EDAMUserStoreConstants EDAM_VERSION_MINOR]];
  if(!versionOK) {
  	[[[[UIAlertView alloc] initWithTitle:@"EDMA Error" message:@"EDMA Version is too old." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease] show];
  	return nil;
  }
  return [userStore authenticate :username :password :SHKEvernoteConsumerKey :SHKEvernoteSecretKey];
}

- (void)authorizationFormValidate:(SHKFormController *)form {
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Logging In...")];
	self.pendingForm = form;
	[NSThread detachNewThreadSelector:@selector(_authorizationFormValidate:) toTarget:self withObject:[form formValues]];
}

- (void)_authorizationFormValidate:(NSDictionary *)args {
	BOOL success = NO;
  @try {
		EDAMAuthenticationResult *authResult = [self getAuthenticationResultForUsername:[args valueForKey:@"username"] password:[args valueForKey:@"password"]];
		success = authResult&&[authResult userIsSet]&&[authResult authenticationTokenIsSet];
  }
  @catch (NSException * e) {
		NSLog(@"Caught %@: %@ %@", [e name], [e reason],e);
	}	
	[self performSelectorOnMainThread:@selector(_authFinished:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:success?@"1":@"0",@"success",nil] waitUntilDone:FALSE];
}

- (void)_authFinished:(NSDictionary *)args {
	[self authFinished:[[args valueForKey:@"success"] isEqualToString:@"1"]];
}

- (void)authFinished:(BOOL)success {
	[[SHKActivityIndicator currentIndicator] hide];
  if(!success) {
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Login Error") message:SHKLocalizedString(@"Your username and password did not match") delegate:nil cancelButtonTitle:SHKLocalizedString(@"Close") otherButtonTitles:nil] autorelease] show];
    return;
  }
  [pendingForm saveForm];
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type {
	return [NSArray arrayWithObjects:
	 [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:item.title],
	 //[SHKFormFieldSettings label:SHKLocalizedString(@"Memo")  key:@"text" type:SHKFormFieldTypeText start:item.text],
	 [SHKFormFieldSettings label:SHKLocalizedString(@"Tags")  key:@"tags" type:SHKFormFieldTypeText start:item.tags],
	 nil];
}

// + (BOOL)canAutoShare { return NO; }

- (void)shareFormValidate:(SHKCustomFormController *)form {	
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
	@try {
		EDAMAuthenticationResult *authResult = [self getAuthenticationResultForUsername:[self getAuthValueForKey:@"username"] password:[self getAuthValueForKey:@"password"]];
    EDAMUser *user = [authResult user];
    authToken    = [authResult authenticationToken];
    noteStoreURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kEvernoteNetStoreURLBase, [user shardId]]];
    THTTPClient *noteStoreHTTPClient = [[[THTTPClient alloc] initWithURL:noteStoreURL] autorelease];
    TBinaryProtocol *noteStoreProtocol = [[[TBinaryProtocol alloc] initWithTransport:noteStoreHTTPClient] autorelease];
    EDAMNoteStoreClient *noteStore = [[[EDAMNoteStoreClient alloc] initWithProtocol:noteStoreProtocol] autorelease];
		SHKEvernoteItem *enItem;
		NSMutableArray *resources;
		EDAMNote *note;
		if([item isKindOfClass:[SHKEvernoteItem class]]) {
			enItem = ((SHKEvernoteItem *)item);
			if(enItem.note) note = ((SHKEvernoteItem *)item).note;
			resources = [note.resources mutableCopy];
		}
		if(!resources) resources = [[NSMutableArray alloc] init];
		if(!note) note = [[[EDAMNote alloc] init] autorelease];
		EDAMNoteAttributes *atr = [note attributesIsSet] ? [note.attributes retain] : [[EDAMNoteAttributes alloc] init];
		if(![atr sourceURLIsSet]&&enItem.URL) [atr setSourceURL:[enItem.URL absoluteString]];
		if(![note notebookGuidIsSet]) [note setNotebookGuid:[[self defaultNoteBookFromNoteStore:noteStore authToken:authToken] guid]];
		note.title = item.title.length > 0 ? item.title : [note titleIsSet] ? note.title: SHKLocalizedString(@"Untitled");
		if(![note tagNamesIsSet]&&item.tags) [note setTagNames:[item.tags componentsSeparatedByString:@" "]];
		if(![note contentIsSet]) {
			NSMutableString* contentStr = [[NSMutableString alloc] initWithString:kENMLPrefix];
			if(item.title.length>0) [contentStr appendFormat:@"<h1>%@</h1>",item.title];
			if(item.text.length>0 ) [contentStr appendFormat:@"<p>%@</p>"  ,item.text];
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
					NSLog(@"%@",e);
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
      NSLog(@"Created note: %@", [createdNote title]);
			success = YES;
    }
  }
  @catch (NSException * e) {
    NSLog(@"%@",e);
  }
	[self performSelectorOnMainThread:@selector(_sendFinished:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:success?@"1":@"0",@"success",nil] waitUntilDone:FALSE];
	[pool release];
}

- (NSString *)enMediaTagWithResource:(EDAMResource *)src width:(CGFloat)width height:(CGFloat)height {
	NSString *sizeAtr = width > 0 && height > 0 ? [NSString stringWithFormat:@"height=\"%.0f\" width=\"%.0f\" ",height,width]:@"";
	return [NSString stringWithFormat:@"<en-media type=\"%@\" %@hash=\"%@\"/>",src.mime,sizeAtr,[src.data.body md5]];
}

- (void)_sendFinished:(NSDictionary *)args {
	[self sendFinished:[[args valueForKey:@"success"] isEqualToString:@"1"]];
}


- (void)sendFinished:(BOOL)success {	
	if (success) {
		[self sendDidFinish];
	} else {
		[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was a problem sharing")] shouldRelogin:YES];
	}
}

@end
