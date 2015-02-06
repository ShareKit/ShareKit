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

#import "SHKConfiguration.h"
#import "NSData+SaveItemAttachment.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SHKFormFieldSettings.h"

NSString * const SHKAttachmentSaveDir = @"SHKAttachmentSaveDir";

@interface SHKItem()

@property (nonatomic, strong) NSMutableDictionary *custom;

- (NSString *)shareTypeToString:(SHKShareType)shareType;

@end

@implementation SHKItem


- (id)init {
    
    self = [super init];
    
    if (self) {
        
        [self setExtensionPropertiesDefaultValues];
    }
    return self;
}

- (void)setExtensionPropertiesDefaultValues {
    
    _printOutputType = [SHKCONFIG(printOutputType) intValue];
    
    _mailToRecipients = SHKCONFIG(mailToRecipients);
    _mailJPGQuality = [SHKCONFIG(mailJPGQuality) floatValue];
    _isMailHTML = [SHKCONFIG(isMailHTML) boolValue];
    _mailShareWithAppSignature = [SHKCONFIG(sharedWithSignature) boolValue];
    
    _facebookURLShareDescription = SHKCONFIG(facebookURLShareDescription);
    _facebookURLSharePictureURI = SHKCONFIG(facebookURLSharePictureURI);
    
    _textMessageToRecipients = SHKCONFIG(textMessageToRecipients);
	_popOverSourceRect = CGRectFromString(SHKCONFIG(popOverSourceRect));
    
    _dropboxDestinationDirectory = SHKCONFIG(dropboxDestinationDirectory);
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
	
	return item;
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
	
	return item;
}

+ (id)text:(NSString *)text
{
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeText;
	item.text = text;
	
	return item;
}

+ (id)filePath:(NSString *)path title:(NSString *)title;
{
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeFile;
    
    SHKFile *file = [[SHKFile alloc] initWithFilePath:path];
    item.file = file;
	item.title = title;
	
	return item;
}

+ (id)fileData:(NSData *)data filename:(NSString *)filename title:(NSString *)title
{
	SHKItem *item = [[self alloc] init];
	item.shareType = SHKShareTypeFile;
    
    if (!filename) filename = title;
    
    SHKFile *file = [[SHKFile alloc] initWithFileData:data filename:filename];
    item.file = file;
	item.title = title;
	
	return item;
}

+ (id)file:(NSData *)data filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title {
    
    return [[self class] fileData:data filename:filename title:title];
}

- (void)convertImageShareToFileShareOfType:(SHKImageConversionType)conversionType quality:(CGFloat)quality {
    
    if (!self.image) return;
    
    self.shareType = SHKShareTypeFile;
    
    NSData *imageData = nil;
    NSString *extension = nil;
    
    switch (conversionType) {
        case SHKImageConversionTypeJPG:
            imageData = UIImageJPEGRepresentation(self.image, quality);
            extension = @"jpg";
            break;
        case SHKImageConversionTypePNG:
            imageData = UIImagePNGRepresentation(self.image);
            extension = @"png";
            break;
        default:
            break;
    }
    
    NSString *rawFileName = nil;
    if (self.title.length > 0) {
        rawFileName = self.title;
    } else {
        rawFileName = @"Image";
    }
    
    NSString *filename = [NSString stringWithFormat:@"%@.%@", rawFileName, extension];
    SHKFile *aFile = [[SHKFile alloc] initWithFileData:imageData filename:filename];
    self.file = aFile;
    
    self.image = nil;
}

#pragma mark -

- (void)setCustomValue:(id)value forKey:(NSString *)key
{
	if (self.custom == nil)
		self.custom = [NSMutableDictionary dictionaryWithCapacity:0];
	
	if (value == nil)
		[self.custom removeObjectForKey:key];
		
	else
		[self.custom setObject:value forKey:key];
}

- (NSString *)customValueForKey:(NSString *)key
{
	return [self.custom objectForKey:key];
}

- (BOOL)customBoolForSwitchKey:(NSString *)key
{
	return [[self.custom objectForKey:key] isEqualToString:SHKFormFieldSwitchOn];
}

#pragma mark ---
#pragma mark NSCoding

static NSString *kSHKShareType = @"kSHKShareType";
static NSString *kSHKURLContentType = @"kSHKURLContentType";
static NSString *kSHKURL = @"kSHKURL";
static NSString *kSHKURLPictureURI = @"kSHKURLPictureURI";
static NSString *kSHKURLDescription = @"kSHKURLDescription";
static NSString *kSHKTitle = @"kSHKTitle";
static NSString *kSHKText = @"kSHKText";
static NSString *kSHKIsHTMLText = @"kSHKIsHTMLText";
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
static NSString *kSHKFacebookURLSharePictureURI = @"kSHKFacebookURLSharePictureURI";
static NSString *kSHKTextMessageToRecipients = @"kSHKTextMessageToRecipients";
static NSString *kSHKPopOverSourceRect = @"kSHKPopOverSourceRect";
static NSString *kSHKDropboxDestinationDir = @"kSHKDropboxDestinationDir";

- (id)initWithCoder:(NSCoder *)decoder {
    
    self = [super init];
    
    if (self) {
        
        _shareType = [decoder decodeIntForKey:kSHKShareType];
        _URLContentType = [decoder decodeIntForKey:kSHKURLContentType];
        _URL = [decoder decodeObjectForKey:kSHKURL];
        _URLPictureURI = [decoder decodeObjectForKey:kSHKURLPictureURI];
        _URLDescription = [decoder decodeObjectForKey:kSHKURLDescription];
        _title = [decoder decodeObjectForKey:kSHKTitle];
        _text = [decoder decodeObjectForKey:kSHKText];
        _isHTMLText = [decoder decodeObjectForKey:kSHKIsHTMLText];
        _tags = [decoder decodeObjectForKey:kSHKTags];
        _custom = [decoder decodeObjectForKey:kSHKCustom];
        _file = [decoder decodeObjectForKey:kSHKFile];
        _image = [UIImage imageWithData:[decoder decodeObjectForKey:kSHKImage]];
        _printOutputType = [decoder decodeIntForKey:kSHKPrintOutputType];
        _mailToRecipients = [decoder decodeObjectForKey:kSHKMailToRecipients];
        _isMailHTML = [decoder decodeBoolForKey:kSHKIsMailHTML];
        _mailJPGQuality = [decoder decodeFloatForKey:kSHKMailJPGQuality];
        _mailShareWithAppSignature = [decoder decodeBoolForKey:kSHKMailShareWithAppSignature];
        _facebookURLShareDescription = [decoder decodeObjectForKey:kSHKFacebookURLShareDescription];
        _facebookURLSharePictureURI = [decoder decodeObjectForKey:kSHKFacebookURLSharePictureURI];
        _textMessageToRecipients = [decoder decodeObjectForKey:kSHKTextMessageToRecipients];
        _popOverSourceRect = CGRectFromString([decoder decodeObjectForKey:kSHKPopOverSourceRect]);
        _dropboxDestinationDirectory = [decoder decodeObjectForKey:kSHKDropboxDestinationDir];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {

    [encoder encodeInt:self.shareType forKey:kSHKShareType];
    [encoder encodeInt:self.URLContentType forKey:kSHKURLContentType];
    [encoder encodeObject:self.URL forKey:kSHKURL];
    [encoder encodeObject:self.URLPictureURI forKey:kSHKURLPictureURI];
    [encoder encodeObject:self.URLDescription forKey:kSHKURLDescription];
    [encoder encodeObject:self.title forKey:kSHKTitle];
    [encoder encodeObject:self.text forKey:kSHKText];
    [encoder encodeBool:self.isHTMLText forKey:kSHKIsHTMLText];
    [encoder encodeObject:self.tags forKey:kSHKTags];
    [encoder encodeObject:self.custom forKey:kSHKCustom];
    [encoder encodeObject:self.file forKey:kSHKFile];
    [encoder encodeObject:UIImagePNGRepresentation(self.image) forKey:kSHKImage];
    [encoder encodeInt:self.printOutputType forKey:kSHKPrintOutputType];
    [encoder encodeObject:self.mailToRecipients forKey:kSHKMailToRecipients];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [encoder encodeBool:self.isMailHTML forKey:kSHKIsMailHTML];
#pragma clang diagnostic pop
    [encoder encodeFloat:self.mailJPGQuality forKey:kSHKMailJPGQuality];
    [encoder encodeBool:self.mailShareWithAppSignature forKey:kSHKMailShareWithAppSignature];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [encoder encodeObject:self.facebookURLShareDescription forKey:kSHKFacebookURLShareDescription];
    [encoder encodeObject:self.facebookURLSharePictureURI forKey:kSHKFacebookURLSharePictureURI];
#pragma clang diagnostic pop
    [encoder encodeObject:self.textMessageToRecipients forKey:kSHKTextMessageToRecipients];
    [encoder encodeObject:NSStringFromCGRect(self.popOverSourceRect) forKey:kSHKPopOverSourceRect];
    [encoder encodeObject:self.dropboxDestinationDirectory forKey:kSHKDropboxDestinationDir];
}

#pragma mark -

- (NSString *)description {

    NSString *result = [NSString stringWithFormat:@"Share type: %@\nURL:%@\n\
                                                    URLContentType: %i\n\
                                                    URLPictureURI: %@\n\
                                                    URLDescription: %@\n\
                                                    Image:%@\n\
                                                    Title: %@\n\
                                                    Text: %@\n\
                                                    Tags:%@\n\
                                                    Custom fields:%@\n\n\
                                                    Sharer specific\n\n\
                                                    Print output type: %li\n\
													mailToRecipients: %@\n\
                                                    isMailHTML: %i\n\
                                                    mailJPGQuality: %f\n\
                                                    mailShareWithAppSignature: %i\n\
                                                    textMessageToRecipients: %@\n\
                                                    popOverSourceRect: %@\n\
                                                    dropboxDestinationDir: %@",
                        
						
                                                    [self shareTypeToString:self.shareType],
                                                    [self.URL absoluteString],
                                                    self.URLContentType,
                                                    [self.URLPictureURI absoluteString],
                                                    self.URLDescription,
                                                    [self.image description], 
                                                    self.title, self.text, 
                                                    self.tags, 
                                                    [self.custom description],
                                                    (long)self.printOutputType,
													self.mailToRecipients,
                                                    self.isHTMLText,
                                                    self.mailJPGQuality,
                                                    self.mailShareWithAppSignature,
                                                    self.textMessageToRecipients,
													NSStringFromCGRect(self.popOverSourceRect),
                                                    self.dropboxDestinationDirectory];
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
