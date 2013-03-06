//
//  SHKItem.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.

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

#import "SHKItem.h"
#import "SHK.h"
#import "SHKConfiguration.h"
#import <MobileCoreServices/MobileCoreServices.h>


@interface SHKItem()

@property (nonatomic, retain) NSMutableDictionary *custom;

- (NSString *)shareTypeToString:(SHKShareType)shareType;

@end


@implementation SHKItem

@synthesize shareType;
@synthesize URL, URLContentType, image, title, text, tags, file;
@synthesize custom;
@synthesize printOutputType;
@synthesize mailToRecipients, mailJPGQuality, isMailHTML, mailShareWithAppSignature, popOverSourceRect;
@synthesize facebookURLSharePictureURI, facebookURLShareDescription;
@synthesize textMessageToRecipients;

- (void)dealloc
{
	[URL release];
	
	[image release];
	
	[title release];
	[text release];
	[tags release];
	
    [file release];
	
	[custom release];

	[mailToRecipients release];
	[facebookURLSharePictureURI release];
	[facebookURLShareDescription release];
  
	[textMessageToRecipients release];
  
	[super dealloc];
}

- (id)init {
    
    self = [super init];
    
    if (self) {
        
        [self setExtensionPropertiesDefaultValues];
    }
    return self;
}

- (void)setExtensionPropertiesDefaultValues {
    
    printOutputType = [SHKCONFIG(printOutputType) intValue];
    
    mailToRecipients = [SHKCONFIG(mailToRecipients) retain];
    mailJPGQuality = [SHKCONFIG(mailJPGQuality) floatValue];
    isMailHTML = [SHKCONFIG(isMailHTML) boolValue];
    mailShareWithAppSignature = [SHKCONFIG(sharedWithSignature) boolValue];
    
    facebookURLShareDescription = [SHKCONFIG(facebookURLShareDescription) retain];
    facebookURLSharePictureURI = [SHKCONFIG(facebookURLSharePictureURI) retain];
    
    textMessageToRecipients = [SHKCONFIG(textMessageToRecipients) retain];
	popOverSourceRect = CGRectFromString(SHKCONFIG(popOverSourceRect));
}

+ (id)URL:(NSURL *)url
{
	return [self URL:url title:nil contentType:SHKURLContentTypeWebpage];
}

+ (id)URL:(NSURL *)url title:(NSString *)title
{
	return [self URL:url title:title contentType:SHKURLContentTypeWebpage];
}

+ (id)URL:(NSURL *)url title:(NSString *)title contentType:(SHKURLContentType)type {
    
    SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeURL;
	item.URL = url;
	item.title = title;
    item.URLContentType = type;
	
	return [item autorelease];
    
}

+ (id)image:(UIImage *)image
{
	return [SHKItem image:image title:nil];
}

+ (id)image:(UIImage *)image title:(NSString *)title
{
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeImage;
	item.image = image;
	item.title = title;
	
	return [item autorelease];
}

+ (id)text:(NSString *)text
{
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeText;
	item.text = text;
	
	return [item autorelease];
}

+ (id)file:(NSString *)path title:(NSString *)title;
{
    SHKFile *file = [[[SHKFile alloc] initWithFile:path] autorelease];
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeFile;
    item.file = file;
	item.title = title;
	
	return [item autorelease];
}

+ (id)file:(NSData *)data filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title;
{
    SHKFile *file = [[[SHKFile alloc] initWithFile:data filename:filename] autorelease];
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeFile;
    item.file = file;
	item.title = title;
	
	return [item autorelease];
}

#pragma mark -

- (void)setCustomValue:(id)value forKey:(NSString *)key
{
	if (custom == nil)
		self.custom = [NSMutableDictionary dictionaryWithCapacity:0];
	
	if (value == nil)
		[custom removeObjectForKey:key];
		
	else
		[custom setObject:value forKey:key];
}

- (NSString *)customValueForKey:(NSString *)key
{
	return [custom objectForKey:key];
}

- (BOOL)customBoolForSwitchKey:(NSString *)key
{
	return [[custom objectForKey:key] isEqualToString:SHKFormFieldSwitchOn];
}


#pragma mark -


#pragma mark ---
#pragma mark NSCoding

static NSString *kSHKShareType = @"kSHKShareType";
static NSString *kSHKURLContentType = @"kSHKURLContentType";
static NSString *kSHKURL = @"kSHKURL";
static NSString *kSHKTitle = @"kSHKTitle";
static NSString *kSHKText = @"kSHKText";
static NSString *kSHKTags = @"kSHKTags";
static NSString *kSHKCustom = @"kSHKCustom";
static NSString *kSHKFile = @"kSHKFile";
static NSString *kSHKImage = @"kSHKImage";
static NSString *kSHKPrintOutputType = @"kSHKPrintOutputType";
static NSString *kSHKMailToRecipients = @"kSHKMailToRecipients";
static NSString *kSHKIsMailHTML = @"kSHKIsMailHTML";
static NSString *kSHKMailJPGQuality = @"kSHKMailJPGQuality";
static NSString *kSHKMailShareWithAppSignature = @"kSHKMailShareWithAppSignature";
static NSString *kSHKFacebookURLShareDescription = @"kSHKFacebookURLShareDescription";
static NSString *kSHKTextMessageToRecipients = @"kSHKTextMessageToRecipients";
static NSString *kSHKPopOverSourceRect = @"kSHKPopOverSourceRect";

-(id)initWithCoder:(NSCoder *)decoder
{
    if(self = [super init]){
        shareType = [decoder decodeIntForKey:kSHKShareType];
        URLContentType = [decoder decodeIntForKey:kSHKURLContentType];
        URL = [[decoder decodeObjectForKey:kSHKURL] retain];
        title = [[decoder decodeObjectForKey:kSHKTitle] retain];
        text = [[decoder decodeObjectForKey:kSHKText] retain];
        tags = [[decoder decodeObjectForKey:kSHKTags] retain];
        
        // Our non-required values
        if([decoder containsValueForKey:kSHKCustom]) custom = [[decoder decodeObjectForKey:kSHKCustom] retain];
        if([decoder containsValueForKey:kSHKFile]) file = [[decoder decodeObjectForKey:kSHKFile] retain];
        if([decoder containsValueForKey:kSHKImage]) image = [[decoder decodeObjectForKey:kSHKImage] retain];
        if([decoder containsValueForKey:kSHKPrintOutputType]) printOutputType = [decoder decodeIntForKey:kSHKPrintOutputType];
        if([decoder containsValueForKey:kSHKMailToRecipients]) mailToRecipients = [[decoder decodeObjectForKey:kSHKMailToRecipients] retain];
        if([decoder containsValueForKey:kSHKIsMailHTML]) isMailHTML = [decoder decodeBoolForKey:kSHKIsMailHTML];
        if([decoder containsValueForKey:kSHKMailJPGQuality]) mailJPGQuality = [decoder decodeFloatForKey:kSHKMailJPGQuality];
        if([decoder containsValueForKey:kSHKMailShareWithAppSignature]) mailShareWithAppSignature = [decoder decodeBoolForKey:kSHKMailShareWithAppSignature];
        if([decoder containsValueForKey:kSHKFacebookURLShareDescription]) facebookURLShareDescription = [[decoder decodeObjectForKey:kSHKFacebookURLShareDescription] retain];
        if([decoder containsValueForKey:kSHKTextMessageToRecipients]) textMessageToRecipients = [[decoder decodeObjectForKey:kSHKTextMessageToRecipients] retain];
        if([decoder containsValueForKey:kSHKPopOverSourceRect]) popOverSourceRect = CGRectFromString([decoder decodeObjectForKey:kSHKPopOverSourceRect]);
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInt:shareType forKey:kSHKShareType];
    [encoder encodeInt:URLContentType forKey:kSHKURLContentType];
    [encoder encodeObject:URL forKey:kSHKURL];
    [encoder encodeObject:title forKey:kSHKTitle];
    [encoder encodeObject:text forKey:kSHKText];
    [encoder encodeObject:tags forKey:kSHKTags];
    
    // Our non-required values
    if(custom) [encoder encodeObject:custom forKey:kSHKCustom];
    if(file) [encoder encodeObject:file forKey:kSHKFile];
    if(image) [encoder encodeObject:image forKey:kSHKImage];
    [encoder encodeInt:printOutputType forKey:kSHKPrintOutputType];
    [encoder encodeObject:mailToRecipients forKey:kSHKMailToRecipients];
    [encoder encodeBool:isMailHTML forKey:kSHKIsMailHTML];
    [encoder encodeFloat:mailJPGQuality forKey:kSHKMailJPGQuality];
    [encoder encodeBool:mailShareWithAppSignature forKey:kSHKMailShareWithAppSignature];
    [encoder encodeObject:facebookURLShareDescription forKey:kSHKFacebookURLShareDescription];
    [encoder encodeObject:textMessageToRecipients forKey:kSHKTextMessageToRecipients];
    [encoder encodeObject:NSStringFromCGRect(popOverSourceRect) forKey:kSHKPopOverSourceRect];
}

- (NSString *)description {
    
    NSString *result = [NSString stringWithFormat:@"Share type: %@\nURL:%@\n\
                                                    URLContentType: %i\n\
                                                    Image:%@\n\
                                                    Title: %@\n\
                                                    Text: %@\n\
                                                    Tags:%@\n\
                                                    Custom fields:%@\n\n\
                                                    Sharer specific\n\n\
                                                    Print output type: %i\n\
													mailToRecipients: %@\n\
                                                    isMailHTML: %i\n\
                                                    mailJPGQuality: %f\n\
                                                    mailShareWithAppSignature: %i\n\
                                                    facebookURLSharePictureURI: %@\n\
                                                    facebookURLShareDescription: %@\n\
                                                    textMessageToRecipients: %@\n\
                                                    popOverSourceRect: %@",
						
                                                    [self shareTypeToString:self.shareType],
                                                    [self.URL absoluteString],
                                                    self.URLContentType,
                                                    [self.image description], 
                                                    self.title, self.text, 
                                                    self.tags, 
                                                    [self.custom description],
                                                    self.printOutputType,
													self.mailToRecipients,
                                                    self.isMailHTML,
                                                    self.mailJPGQuality,
                                                    self.mailShareWithAppSignature,
                                                    self.facebookURLSharePictureURI,
                                                    self.facebookURLShareDescription,
                                                    self.textMessageToRecipients,
													NSStringFromCGRect(self.popOverSourceRect)];
    
    return result;
}

- (NSString *)shareTypeToString:(SHKShareType)type {
    
    NSString *result = nil;
    
    switch(type) {
            
        case SHKShareTypeUndefined:
            result = @"SHKShareTypeUndefined";
            break;
        case SHKShareTypeURL:
            result = @"SHKShareTypeURL";
            break;
        case SHKShareTypeText:
            result = @"SHKShareTypeText";
            break;
        case SHKShareTypeImage:
            result = @"SHKShareTypeImage";
            break;
        case SHKShareTypeFile:
            result = @"SHKShareTypeFile";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    
    return result;
}


@end
