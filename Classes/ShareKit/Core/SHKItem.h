//
//  SHKItem.h
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

#import <Foundation/Foundation.h>
#import "SHKFile.h"

extern NSString * const SHKAttachmentSaveDir;

typedef enum 
{
	SHKShareTypeUndefined,
	SHKShareTypeURL,
	SHKShareTypeText,
	SHKShareTypeImage,
	SHKShareTypeFile,
    SHKShareTypeUserInfo
    
} SHKShareType;

typedef enum 
{
    SHKURLContentTypeUndefined,
    SHKURLContentTypeWebpage,
    SHKURLContentTypeAudio,
    SHKURLContentTypeVideo,
    SHKURLContentTypeImage
    
} SHKURLContentType;

typedef enum
{
    SHKImageConversionTypeJPG,
    SHKImageConversionTypePNG
    
} SHKImageConversionType;

@interface SHKItem : NSObject <NSCoding>

@property (nonatomic) SHKShareType shareType;

@property (nonatomic, strong)	NSString *title;
@property (nonatomic, strong)	NSString *text;
@property (nonatomic, strong)	NSArray *tags;

@property (nonatomic, strong)	NSURL *URL;
@property (nonatomic) SHKURLContentType URLContentType;
@property (nonatomic, strong)	UIImage *image;

@property (nonatomic, strong) SHKFile *file;

/*** creation methods ***/

/* always use these for SHKItem object creation, as they implicitly set appropriate SHKShareType. Items without SHKShareType will not be shared! */

+ (id)URL:(NSURL *)url title:(NSString *)title __attribute__((deprecated ("use URL:title:contentType: instead")));

//Some sharers might present audio and video urls in enhanced way - e.g with media player (see Tumblr sharer). Other sharers share same way they used to, regardless of what type is specified.
+ (id)URL:(NSURL *)url title:(NSString *)title contentType:(SHKURLContentType)type;
+ (id)image:(UIImage *)image title:(NSString *)title;
+ (id)text:(NSString *)text;

//use this method if you share file from the disk.
+ (id)filePath:(NSString *)path title:(NSString *)title;

//use only if user needs to share in-memory data. Temporary files may be created. Make sure you pass filename with correct extension, as mimetype is derived from the extension.
+ (id)file:(NSData *)data filename:(NSString *)filename mimeType:(NSString *)mimeType title:(NSString *)title __attribute__((deprecated ("use new filePath:title or in case you share in-memory data fileData:filename:title. Mimetype is derived from filename, regardless of what you set")));
+ (id)fileData:(NSData *)data filename:(NSString *)filename title:(NSString *)title;

//some sharers need to share UIImage as data file, this makes the conversion
- (void)convertImageShareToFileShareOfType:(SHKImageConversionType)conversionType quality:(CGFloat)quality;

/*** custom value methods ***/

/* these are for custom properties injection. Use them only if you are adding some custom functionality to your sharer subclass. */

- (void)setCustomValue:(id)value forKey:(NSString *)key;
- (NSString *)customValueForKey:(NSString *)key;
- (BOOL)customBoolForSwitchKey:(NSString *)key;

/*** sharer specific extension properties ***/

/* sharers might be instructed to share the item in specific ways, e.g. SHKPrint's print quality, SHKMail's send to specified recipients etc. 
 Generally, YOU DO NOT NEED TO SET THESE, as sharers perfectly work with automatic default values. You can change default values in your app's 
 configurator, or individually during SHKItem creation. Example is in the demo app - ExampleShareLink.m - share method. More info about 
 particular setting is in DefaultSHKConfigurator.m
 */

/* SHKPrint */
@property (nonatomic) UIPrintInfoOutputType printOutputType;

/* SHKMail */
@property (nonatomic, strong) NSArray *mailToRecipients;
@property BOOL isMailHTML;
@property CGFloat mailJPGQuality; 
@property BOOL mailShareWithAppSignature; //default NO. Appends "Sent from <appName>"

/* SHKFacebook */
@property (nonatomic, strong) NSString *facebookURLSharePictureURI;
@property (nonatomic, strong) NSString *facebookURLShareDescription;

/* SHKTextMessage */
@property (nonatomic, strong) NSArray *textMessageToRecipients;
/* if you add new sharer specific properties, make sure to add them also to dictionaryRepresentation, itemWithDictionary and description methods in SHKItem.m */

/* put in for SHKInstagram, but could be useful in some other place. This is the rect in the coordinates of the view of the viewcontroller set with
 setRootViewController: where a popover should eminate from. If this isn't provided the popover will be presented from the top left. */
@property (nonatomic, assign) CGRect popOverSourceRect;

@end
