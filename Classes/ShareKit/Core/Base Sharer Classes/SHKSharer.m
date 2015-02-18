    //
//  SHKSharer.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/8/10.

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
//

#import "SHKSharer.h"

#import "SHKSharerDelegate.h"
#import "SHKRequest.h"
#import "SharersCommonHeaders.h"
#import "SHKUploadInfo.h"
#import "SHKSession.h"

static NSString *const kSHKStoredItemKey=@"kSHKStoredItem";
static NSString *const kSHKStoredActionKey=@"kSHKStoredAction";
static NSString *const kSHKStoredShareInfoKey=@"kSHKStoredShareInfo";

@interface SHKSharer ()

- (void)updateItemWithForm:(SHKFormController *)form;

@end

@implementation SHKSharer

- (void)dealloc {
    
    _dic.delegate = nil;
    SHKLog(@"!!! %@ sharer deallocated!!!", [self sharerTitle]);
}

#pragma mark -
#pragma mark Configuration : Service Defination

// Each service should subclass these and return YES/NO to indicate what type of sharing they support.
// Superclass defaults to NO so that subclasses only need to add methods for types they support

+ (NSString *)sharerTitle
{
	return @"";
}

- (NSString *)sharerTitle
{
	return [[self class] sharerTitle];
}

+ (NSString *)sharerId
{
	return NSStringFromClass([self class]);
}

- (NSString *)sharerId
{
	return [[self class] sharerId];	
}

+ (BOOL)canShareText
{
	return NO;
}

+ (BOOL)canShareURL
{
	return NO;
}

- (BOOL)requiresShortenedURL
{
    return NO;
}

+ (BOOL)canShareImage
{
	return NO;
}

+ (BOOL)canShareFile:(SHKFile *)file;
{
	return NO;
}

+ (BOOL)canGetUserInfo
{
    return NO;
}

+ (BOOL)shareRequiresInternetConnection
{
	return YES;
}

+ (BOOL)canShareOffline
{
	return YES;
}

+ (BOOL)requiresAuthentication
{
	return YES;
}

+ (BOOL)canShareItem:(SHKItem *)item
{
	switch (item.shareType)
	{
		case SHKShareTypeURL:
			return [self canShareURL];
			
		case SHKShareTypeImage:
			return [self canShareImage];
			
		case SHKShareTypeText:
			return [self canShareText];
			
		case SHKShareTypeFile:
			return [self canShareFile:item.file];
            
        case SHKShareTypeUserInfo:
			return [self canGetUserInfo];
			
		default: 
			break;
	}
	return NO;
}

+ (BOOL)canAutoShare
{
	return YES;
}



#pragma mark -
#pragma mark Configuration : Dynamic Enable

// Allows a subclass to programically disable/enable services depending on the current environment

+ (BOOL)canShare
{
	return YES;
}

- (BOOL)shouldAutoShare
{	
	return [[NSUserDefaults standardUserDefaults] boolForKey:[NSString stringWithFormat:@"%@_shouldAutoShare", [self sharerId]]];
}

#pragma mark -
#pragma mark Initialization

- (id)init
{
	if (self = [super initWithNibName:nil bundle:nil])
	{
        _shareDelegate = [[SHKCONFIG(SHKSharerDelegateSubclass) alloc] init];
				
		if ([self respondsToSelector:@selector(modalPresentationStyle)])
			self.modalPresentationStyle = [SHK modalPresentationStyleForController:self];
		
		if ([self respondsToSelector:@selector(modalTransitionStyle)])
			self.modalTransitionStyle = [SHK modalTransitionStyleForController:self];
	}
	return self;
}

#pragma mark -
#pragma mark Share Item Loading Convenience Methods

+ (id)shareItem:(SHKItem *)i
{
	if ([self canShareItem:i]) {
        
        [SHK pushOnFavorites:[self sharerId] forItem:i];
        
        // Create controller and set share options
        SHKSharer *controller = [[self alloc] init];
        controller.item = i;
        
        // share and/or show UI
        [controller share];
        
        return controller;
        
    } else {
        
        SHKLog(@"Warning!!! You are loading sharer with incompatible item");
        return nil;
    }
}

- (void)loadItem:(SHKItem *)i
{
    if ([[self class] canShareItem:i]) {
        
        [SHK pushOnFavorites:[self sharerId] forItem:i];
        self.item = i;
        
    } else {
        
        SHKLog(@"Warning!!! You are loading sharer with incompatible item");
    }
}

+ (id)shareURL:(NSURL *)url
{
	return [self shareURL:url title:nil];
}

+ (id)shareURL:(NSURL *)url title:(NSString *)title
{
    SHKItem *item = [SHKItem URL:url title:title contentType:SHKURLContentTypeWebpage];
    
    // Create controller and set share options
	SHKSharer *controller = [[self alloc] init];
    [controller loadItem:item];

	// share and/or show UI
	[controller share];

	return controller;
}

+ (id)shareImage:(UIImage *)image title:(NSString *)title
{
    SHKItem *item = [SHKItem image:image title:title];
	
    // Create controller and set share options
	SHKSharer *controller = [[self alloc] init];
    [controller loadItem:item];
	
	// share and/or show UI
	[controller share];
	
	return controller;
}

+ (id)shareText:(NSString *)text
{
	SHKItem *item = [SHKItem text:text];
    // Create controller and set share options
	SHKSharer *controller = [[self alloc] init];
    [controller loadItem:item];
	
	// share and/or show UI
	[controller share];
	
	return controller;
}

+ (id)shareFile:(NSData *)file filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title
{
    return [[self class] shareFileData:file filename:filename title:title];
}

+ (id)shareFileData:(NSData *)data filename:(NSString *)filename title:(NSString *)title
{
    SHKItem *item = [SHKItem fileData:data filename:filename title:title];
    
    // Create controller and set share options
	SHKSharer *controller = [[self alloc] init];
    [controller loadItem:item];
	
	// share and/or show UI
	[controller share];
	
	return controller;
}

+ (id)shareFilePath:(NSString *)path title:(NSString *)title
{
    SHKItem *item = [SHKItem filePath:path title:title];
    
    // Create controller and set share options
	SHKSharer *controller = [[self alloc] init];
    [controller loadItem:item];
	
	// share and/or show UI
	[controller share];
	
	return controller;
}

+ (id)getUserInfo
{
    SHKItem *item = [[SHKItem alloc] init];
    item.shareType = SHKShareTypeUserInfo;
    
    if ([self canShareItem:item]) {
        
        // Create controller and set share options
        SHKSharer *controller = [[self alloc] init];
        controller.item = item;
        
        // share and/or show UI
        [controller share];
        return controller;

    } else {
        
        SHKLog(@"Warning!!! This sharer does not fetch user info.");
        return nil;
    }
}

#pragma mark - Share Item temporary save

- (BOOL)restoreItem {
    
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *storedShareInfo = [defaults objectForKey:kSHKStoredShareInfoKey];
    
	if (storedShareInfo)
	{
        self.item = [NSKeyedUnarchiver unarchiveObjectWithData:[storedShareInfo objectForKey:kSHKStoredItemKey]];
		self.pendingAction = [[storedShareInfo objectForKey:kSHKStoredActionKey] intValue];
        [[self class] clearSavedItem];
    }
	return storedShareInfo != nil;
}

+ (void)clearSavedItem {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSHKStoredShareInfoKey];
    [defaults synchronize];
}

- (void)saveItemForLater:(SHKSharerPendingAction)inPendingAction {
    
    if (!self.item) return;
    
    NSData *itemData = [NSKeyedArchiver archivedDataWithRootObject:self.item];
    NSDictionary *shareInfo = @{kSHKStoredItemKey: itemData,
                               kSHKStoredActionKey : [NSNumber numberWithInt:inPendingAction]};
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:shareInfo forKey:kSHKStoredShareInfoKey];
    [defaults synchronize];
}

#pragma mark - Share Item URL Shortening

- (void)shortenURL
{
	NSString *bitLyLogin = SHKCONFIG(bitLyLogin);
	NSString *bitLyKey = SHKCONFIG(bitLyKey);
	BOOL bitLyConfigured = [bitLyLogin length] > 0 && [bitLyKey length] > 0;
	
	if (bitLyConfigured == NO || ![SHK connected]) {
        SHKLog(@"URL was not shortened! Make sure you have bit.ly credentials");
        [self show];
        return;
    }
	
	[self displayActivity:SHKLocalizedString(@"Shortening URL...")];
    
	[SHKRequest startWithURL:[NSURL URLWithString:[NSMutableString stringWithFormat:@"http://api.bit.ly/v3/shorten?login=%@&apikey=%@&longUrl=%@&format=txt",
                                                   bitLyLogin,
                                                   bitLyKey,
                                                   SHKEncodeURL(self.item.URL)
                                                   ]]
                      params:nil
                      method:@"GET"
                  completion:^(SHKRequest *request) {
                      
                      [self hideActivityIndicator];
                      
                      NSString *result = [[request getResult] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                      
                      if (!request.success || result == nil || [NSURL URLWithString:result] == nil)
                      {
                          SHKLog(@"URL was not shortened! Error response:%@", result);
                      }
                      else
                      {
                          //if really shortened, set new URL
                          if (![result isEqualToString:@"ALREADY_A_BITLY_LINK"]) {
                              NSURL *newURL = [NSURL URLWithString:result];
                              self.item.URL = newURL;
                          }
                      }
                      
                      if ([self shouldShareSilently]) {
                          [self tryToSend];
                      } else {
                          [self show];
                      }
                  }];
}

#pragma mark -
#pragma mark Commit Share

- (void)share
{
    if (![NSThread isMainThread]) {
        SHKLog(@"You are calling share on a secondary thread. You should always call share on a main thread to make sure a sharer works properly.");
    }
	// isAuthorized - If service requires login and details have not been saved, present login dialog
	if (![self authorize]) {
        
		self.pendingAction = SHKPendingShare;
        return;
    }
    
    BOOL isSharerReady = [self isSharerReady];
    if (!isSharerReady) {
        return;
    }
    
    BOOL shouldShortenURL = self.item.URL && [self requiresShortenedURL];
    if (shouldShortenURL) {
        [self shortenURL];
        return;
    }
    
    if ([self shouldShareSilently]) {
        [self tryToSend];
    } else {
        [self show];
    }
}

//insertion point for sharers, which must have fulfilled more conditions for sharing, e.g. available user account in settings.app for iOS sharers. Evaluated within share method, before actually sharing.
- (BOOL)isSharerReady {
    
    return YES;
}

- (BOOL)shouldShareSilently {
    
    BOOL result = [SHKCONFIG(allowAutoShare) boolValue] == TRUE && [self shouldAutoShare];
    return result;
}

- (void)cancel {
    
    if (!self.networkSession) SHKLog(@"This sharer does not use SHKSession. Default implementation of cancel does nothing!!!");
    
    [self.networkSession cancel];
}

#pragma mark -
#pragma mark Authentication

- (BOOL)isAuthorized
{	
	if (![[self class] requiresAuthentication])
		return YES;
	
	// Checks to make sure we just have at least one variable from the authorization form
	// If the send request fails it'll reprompt the user for their new login anyway
	
	NSString *sharerId = [self sharerId];
	NSArray *fields = [self authorizationFormFields];
	for (SHKFormFieldSettings *field in fields)
	{
		if ([SHK getAuthValueForKey:field.key forSharer:sharerId] != nil)
			return YES;
	}
	
	return NO;
}

- (BOOL)authorize
{
	if ([self isAuthorized])
		return YES;
	
	else 
		[self promptAuthorization];
	
	return NO;
}

- (void)promptAuthorization
{
	if ([[self class] shareRequiresInternetConnection] && ![SHK connected])
	{
		if (!self.quiet)
		{
			[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Offline")
										 message:SHKLocalizedString(@"You must be online to login to %@", [self sharerTitle])
										delegate:nil
							   cancelButtonTitle:SHKLocalizedString(@"Close")
							   otherButtonTitles:nil] show];
		}
		return;
	}
	
	[self authorizationFormShow];
}

- (NSString *)getAuthValueForKey:(NSString *)key
{
	return [SHK getAuthValueForKey:key forSharer:[self sharerId]];
}

- (void)setShouldAutoShare:(BOOL)b
{
	[[NSUserDefaults standardUserDefaults] setBool:b forKey:[NSString stringWithFormat:@"%@_shouldAutoShare", [self sharerId]]];
}

#pragma mark Authorization Form

- (void)authorizationFormShow
{	
	// Create the form
	SHKFormController *form = [[SHKCONFIG(SHKFormControllerSubclass) alloc] initWithStyle:UITableViewStyleGrouped title:SHKLocalizedString(@"Login") rightButtonTitle:SHKLocalizedString(@"Login")];
	[form addSection:[self authorizationFormFields] header:nil footer:[self authorizationFormCaption]];

    form.validateBlock = [self authorizationFormValidate];
	form.saveBlock = [self authorizationFormSave];
	form.cancelBlock = [self authorizationFormCancel];
	form.autoSelect = YES;
	
    [self pushViewController:form animated:NO];
    
	[[SHK currentHelper] showViewController:self];
}

- (FormControllerCallback)authorizationFormValidate;
{
	FormControllerCallback result = ^(SHKFormController *form){
        
        /*
         
         Services should subclass this.
         You can get a dictionary of the field values from [form formValues]
         
         --
         
         You should perform one of the following actions:
         
         1.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
         
         2.	Save the form - If everything is correct call [form saveForm]
         
         3.	Display a pending indicator - If you need to authorize the details on the server, display an activity indicator with [form displayActivity:@"DESCRIPTION OF WHAT YOU ARE DOING"]
         After your process completes be sure to perform either 1 or 2 above.
	 	 
         */
        
    };
    return result;
}

- (FormControllerCallback)authorizationFormSave;
{		
    __weak typeof(self) weakSelf = self;
    FormControllerCallback result = ^(SHKFormController *form) {
        
        // -- Save values
        NSDictionary *formValues = [form formValues];
        
        NSString *value;
        NSString *sharerId = [weakSelf sharerId];
        NSArray *fields = [[[form sections] objectAtIndex:0] objectForKey:@"rows"];
        for(SHKFormFieldSettings *field in fields)
        {
            value = [formValues objectForKey:field.key];
            [SHK setAuthValue:value forKey:field.key forSharer:sharerId];
        }	
		
        // -- Try to share again
        [weakSelf tryPendingAction];
    };
    return result;
}

- (FormControllerCallback)authorizationFormCancel;
{
	__weak typeof(self) weakSelf = self;
    FormControllerCallback result = ^(SHKFormController *form) {
        
        [weakSelf sendDidCancel];
    };
    return result;
}

- (NSArray *)authorizationFormFields
{
	return [[self class] authorizationFormFields];
}

+ (NSArray *)authorizationFormFields
{
	return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeTextNoCorrect start:nil],
			[SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],			
			nil];
}

- (NSString *)authorizationFormCaption
{
	return [[self class] authorizationFormCaption];
}

+ (NSString *)authorizationFormCaption
{
	return nil;
}

+ (void)logout
{
	NSString *sharerId = [self sharerId];
	NSArray *authFields = [self authorizationFormFields];
	if (authFields != nil)
	{
		for(SHKFormFieldSettings *field in authFields)
			[SHK removeAuthValueForKey:field.key forSharer:sharerId];
	}	
}

+ (NSString *)username {
    
    NSString *result = [SHK getAuthValueForKey:@"username" forSharer:[self sharerId]];
    return result;
}

// Credit: GreatWiz
+ (BOOL)isServiceAuthorized 
{	
	SHKSharer *controller = [[self alloc] init];
	BOOL isAuthorized = [controller isAuthorized];
	
	return isAuthorized;	
}

#pragma mark -
#pragma mark UI Implementation

- (void)show
{
	NSArray *shareFormFields = [self shareFormFieldsForType:self.item.shareType];
	
	if (shareFormFields == nil)
		[self tryToSend];
	
	else 
	{	
		SHKFormController *rootView = [[SHKCONFIG(SHKFormControllerSubclass) alloc] initWithStyle:UITableViewStyleGrouped 
																		 title:nil
															  rightButtonTitle:SHKLocalizedString(@"Send to %@", [[self class] sharerTitle])
									   ];
        
        [self setupFormController:rootView withFields:shareFormFields];
				
		[self pushViewController:rootView animated:NO];
		
		[[SHK currentHelper] showViewController:self];
	}
}

- (void)setupFormController:(SHKFormController *)rootView withFields:(NSArray *)shareFormFields {
    
    [rootView addSection:shareFormFields header:nil footer:self.item.URL!=nil?self.item.URL.absoluteString:nil];
    
    if ([SHKCONFIG(allowAutoShare) boolValue] == TRUE && [[self class] canAutoShare])
    {
        [rootView addSection:
         [NSArray arrayWithObject:
          [SHKFormFieldSettings label:SHKLocalizedString(@"Auto Share") key:@"autoShare" type:SHKFormFieldTypeSwitch start:([self shouldAutoShare]?SHKFormFieldSwitchOn:SHKFormFieldSwitchOff)]
          ]
                      header:nil
                      footer:SHKLocalizedString(@"Enable auto share to skip this step in the future.")];
    }
    
    rootView.validateBlock = [self shareFormValidate];
    rootView.saveBlock = [self shareFormSave];
    rootView.cancelBlock = [self shareFormCancel];
}

- (void)openInteractionControllerFileURL:(NSURL *)documentFileURL UTI:(NSString *)UTI annotation:(NSDictionary *)annotationDict {
    
    self.dic = [UIDocumentInteractionController interactionControllerWithURL:documentFileURL];
    self.dic.UTI = UTI;
    self.dic.annotation = annotationDict;
    self.dic.delegate = self;
    
    UIView* bestView = self.view;
    if(bestView.window == nil){
        // we haven't been presented yet, so we're not in the hierarchy. On the iPad the DIC is
        // presented in a popover and that really wants a view rooted in a window. Since we
        // set the rootViewController in the controller that presents this one, we can use it
        UIViewController* crvc = [[SHK currentHelper] rootViewForUIDisplay];
        if (crvc != nil && crvc.view.window != nil ) {
            bestView = crvc.view;
        }
    }
    if(bestView.window != nil){
        [[SHK currentHelper] keepSharerReference:self];	// retain ourselves until the menu has done it's job or we'll nuke the popup (see documentInteractionControllerDidDismissOpenInMenu)
        [self.dic presentOpenInMenuFromRect:self.item.popOverSourceRect inView:bestView animated:YES];
    }
}

#pragma mark -
#pragma mark Share Form

- (NSArray *)shareFormFieldsForType:(SHKShareType)type
{
	//this is abstract method. Services which do not present their own UI should override this to present SHKFormController e.g like this
    
    /*	if (type == SHKShareTypeURL)
     return [NSArray arrayWithObjects:
     [SHKFormFieldSettings label:SHKLocalizedString(@"Title") key:@"title" type:SHKFormFieldTypeText start:self.item.title],
     nil];*/
    
    return nil;
}

- (FormControllerCallback)shareFormValidate
{	
    FormControllerCallback result = ^(SHKFormController *form) {
        
        /*
         
         Services should subclass this if they need to validate any data before sending.
         You can get a dictionary of the field values from [form formValues]
         
         --
         
         You should perform one of the following actions:
         
         1.	Display an error - If the user input was incorrect, display an error to the user and tell them what to do to fix it
         
         2.	Save the form - If everything is correct call [form save]
         
         3.	Display a pending indicator - If you need to authorize the details on the server, display an activity indicator with [form displayActivity:@"DESCRIPTION OF WHAT YOU ARE DOING"]
         After your process completes be sure to perform either 1 or 2 above.
         
         */
        
        
        // default does no checking and proceeds to share
        [form saveForm];
    };
    return result;
}

- (FormControllerCallback)shareFormSave
{		
    __weak typeof(self) weakSelf = self;
    FormControllerCallback result = ^(SHKFormController *form) {
        
        [weakSelf updateItemWithForm:form];
        
        // Update shouldAutoShare
        if ([SHKCONFIG(allowAutoShare) boolValue] == TRUE && [[weakSelf class] canAutoShare])
        {
            NSDictionary *advancedOptions = [form formValuesForSection:1];
            if ([advancedOptions objectForKey:@"autoShare"] != nil)
                [weakSelf setShouldAutoShare:[[advancedOptions objectForKey:@"autoShare"] isEqualToString:SHKFormFieldSwitchOn]];
        }
        
        // Send the share
        [weakSelf tryToSend];
    };
    return result;
}

- (FormControllerCallback)shareFormCancel
{
	__weak typeof(self) weakSelf = self;
    FormControllerCallback result = ^(SHKFormController *form) {
        
        [weakSelf sendDidCancel];
    };
    return result;
}

#pragma mark -

- (NSString *)tagStringJoinedBy:(NSString *)joinString allowedCharacters:(NSCharacterSet *)charset tagPrefix:(NSString *)prefixString tagSuffix:(NSString *)suffixString {
    
    NSMutableArray *cleanedTags = [NSMutableArray arrayWithCapacity:[self.item.tags count]];
    NSCharacterSet *removeSet = [charset invertedSet];
    
    for (NSString *tag in self.item.tags) {
        
        NSString *strippedTag;
        if (removeSet) {
            strippedTag = [[tag componentsSeparatedByCharactersInSet:removeSet] componentsJoinedByString:@""];
        } else {
            strippedTag = tag;
        }
                                 
        if ([strippedTag length] < 1) continue;
        strippedTag = [strippedTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([strippedTag length] < 1) continue;
        
        if ([prefixString length] > 0) {
            strippedTag = [prefixString stringByAppendingString:strippedTag];
        }
        
        if ([suffixString length] > 0) {
            strippedTag = [strippedTag stringByAppendingString:suffixString];
        }
        
        [cleanedTags addObject:strippedTag];
    }
    
    if ([cleanedTags count] < 1) return @"";
    return [cleanedTags componentsJoinedByString:joinString];
}

#pragma mark -

- (void)updateItemWithForm:(SHKFormController *)form
{
	// Update item with new values from form
    NSDictionary *formValues = [form formValues];
	for(NSString *key in formValues)
	{
		if ([key isEqualToString:@"title"])
			self.item.title = [formValues objectForKey:key];
		
		else if ([key isEqualToString:@"text"])
			self.item.text = [formValues objectForKey:key];
		
		else if ([key isEqualToString:@"tags"]) {
            NSString *unparsedTags = [formValues objectForKey:key];
            NSArray *tmpValues = [unparsedTags componentsSeparatedByString:@","];
            NSMutableArray *values = [NSMutableArray arrayWithCapacity:[tmpValues count]];
            for (NSString *a_tag in tmpValues) {
                [values addObject:[a_tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
            }
			self.item.tags = values;
        }
		
		else
			[self.item setCustomValue:[formValues objectForKey:key] forKey:key];
	}
}

#pragma mark -
#pragma mark API Implementation

- (BOOL)validateItem
{
	switch (self.item.shareType)
	{
		case SHKShareTypeURL:
			return (self.item.URL != nil);
			
		case SHKShareTypeImage:
			return (self.item.image != nil);
			
		case SHKShareTypeText:
			return (self.item.text != nil);
			
		case SHKShareTypeFile:
			return (self.item.file != nil);
            
        case SHKShareTypeUserInfo:
            return [[self class] canGetUserInfo];
		default:
			break;
	}
	
	return NO;
}

- (BOOL)tryToSend
{
	if (![[self class] shareRequiresInternetConnection] || [SHK connected])
		return [self send];
	
	else if ([SHKCONFIG(allowOffline) boolValue] == TRUE && [[self class] canShareOffline])
		return [SHK addToOfflineQueue:self.item forSharer:[self sharerId]];
	
	else if (!self.quiet)
	{
		[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Offline")
									 message:SHKLocalizedString(@"You must be online in order to share with %@", [self sharerTitle])
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] show];
		
		return YES;
	}
	
	
	return NO;
}

- (BOOL)send
{	
	// Does not actually send anything.
	// Your subclass should implement the sending logic.
	// There is no reason to call [super send] in your subclass
	
	// You should never call [XXX send] directly, you should use [XXX tryToSend].  TryToSend will perform an online check before trying to send.
	return NO;
}

#pragma mark -
#pragma mark Pending Actions

- (void)tryPendingAction
{
	switch (self.pendingAction)
	{
		case SHKPendingRefreshToken:
        case SHKPendingSend:    
			
            //resend silently
            [self tryToSend];
            
            //to show alert if reshare finishes with error (see SHKSharerDelegate)
            self.pendingAction = SHKPendingNone;            
            break;        
        case SHKPendingShare:
                    
            //show UI or autoshare
			[self share];
            
            //to show alert if reshare finishes with error (see SHKSharerDelegate)
            self.pendingAction = SHKPendingNone;
			break;
		default:
			break;
	}
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

#pragma mark -
#pragma mark Delegate Notifications

- (void)sendDidStart
{		
    [[NSNotificationCenter defaultCenter] postNotificationName:SHKSendDidStartNotification object:self];
    
	if ([self.shareDelegate respondsToSelector:@selector(sharerStartedSending:)])
		[self.shareDelegate performSelector:@selector(sharerStartedSending:) withObject:self];	
}

- (void)sendDidFinish
{
    [self sendDidFinishWithResponse:nil];
}

- (void)sendDidFinishWithResponse:(NSDictionary *)response {
    
    if (self.uploadInfo) {
        self.uploadInfo.uploadFinishedSuccessfully = YES;
        [[SHK currentHelper] uploadInfoChanged:self.uploadInfo];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHKSendDidFinishNotification object:self userInfo:response];
    
    if ([self.shareDelegate respondsToSelector:@selector(sharerFinishedSending:)])
		[self.shareDelegate performSelector:@selector(sharerFinishedSending:) withObject:self];
}

- (void)shouldReloginWithPendingAction:(SHKSharerPendingAction)action
{
    if (action == SHKPendingShare) {
        
        if (self.curOptionController) {
            [self popViewControllerAnimated:NO];//dismiss option controller
            NSAssert([[self topViewController] isKindOfClass:[SHKFormController class]], @"topViewController must be SHKFormController now!");
            [self updateItemWithForm:(SHKFormController *)self.topViewController];
        }        
    }
    
    self.pendingAction = action;
	[self sendDidFailWithError:[SHK error:SHKLocalizedString(@"Could not authenticate you. Please relogin.")] shouldRelogin:YES];
}

- (void)sendDidFailWithError:(NSError *)error
{
	[self sendDidFailWithError:error shouldRelogin:NO];	
}

- (void)sendDidFailWithError:(NSError *)error shouldRelogin:(BOOL)shouldRelogin
{
	self.lastError = error;
    
    if (self.uploadInfo) {
        [[SHK currentHelper] uploadInfoChanged:self.uploadInfo];//to save last progress into defaults
    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:SHKSendDidFailWithErrorNotification object:self];
    
	if ([self.shareDelegate respondsToSelector:@selector(sharer:failedWithError:shouldRelogin:)])
		[self.shareDelegate sharer:self failedWithError:error shouldRelogin:shouldRelogin];
    
    if (shouldRelogin) {
        [self promptAuthorization];
	}
}

- (void)sendDidCancel
{
    if (self.uploadInfo) {
        
        self.uploadInfo.uploadCancelled = YES;
        [[SHK currentHelper] uploadInfoChanged:self.uploadInfo];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHKSendDidCancelNotification object:self];
    
    if ([self.shareDelegate respondsToSelector:@selector(sharerCancelledSending:)])
		[self.shareDelegate performSelector:@selector(sharerCancelledSending:) withObject:self];	
}

- (void)authDidFinish:(BOOL)success	
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHKAuthDidFinishNotification object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:success] forKey:@"success"]];
    
    if ([self.shareDelegate respondsToSelector:@selector(sharerAuthDidFinish:success:)]) {		
        [self.shareDelegate sharerAuthDidFinish:self success:success];
    }
}

- (void)authShowBadCredentialsAlert {
    
    if ([self.shareDelegate respondsToSelector:@selector(sharerShowBadCredentialsAlert:)]) {		
        [self.shareDelegate sharerShowBadCredentialsAlert:self];
    }
}

- (void)authShowOtherAuthorizationErrorAlert {
    
    if ([self.shareDelegate respondsToSelector:@selector(sharerShowOtherAuthorizationErrorAlert:)]) {
        [self.shareDelegate sharerShowOtherAuthorizationErrorAlert:self];
    }
}

- (void)sendShowSimpleErrorAlert {
    
    [self sendDidFailWithError:[SHK error:SHKLocalizedString(@"There was a problem saving to %@.", [[self class] sharerTitle])]];
}

- (void)hideActivityIndicator {
    
    [self.shareDelegate hideActivityIndicatorForSharer:self];
}

- (void)displayActivity:(NSString *)activityDescription {
    
    [self.shareDelegate displayActivity:activityDescription forSharer:self];
}

- (void)displayCompleted:(NSString *)completionText {
    
    [self.shareDelegate displayCompleted:completionText forSharer:self];
}

#pragma mark - SHKSessionDelegate

- (void)showUploadedBytes:(int64_t)uploadedBytes totalBytes:(int64_t)totalBytes {
    
    //SHKLog(@"totalSent:%lli, totalExpected:%lli", uploadedBytes, totalBytes);
    
    if (!self.uploadInfo) {
        
        self.uploadInfo = [[SHKUploadInfo alloc] initWithSharer:self];
        if (totalBytes > 0) {
            self.uploadInfo.bytesTotal = totalBytes;
        }
        [[SHK currentHelper] uploadInfoChanged:self.uploadInfo];
    }
    
    self.uploadInfo.bytesUploaded = uploadedBytes;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SHKUploadProgressNotification object:self userInfo:@{SHKUploadProgressInfoKeyName: self.uploadInfo}];
    [self.shareDelegate showProgress:[self.uploadInfo uploadProgress] forSharer:self];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    
    if (self.didSend) {
        
        self.quiet = YES; //so that we do not show "Saved!" prematurely
        [self sendDidFinish];
        
    } else {
        
        [self sendDidCancel];
    }
    [[SHK currentHelper] removeSharerReference:self];
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *) application {
    
    self.didSend = true;
}

@end