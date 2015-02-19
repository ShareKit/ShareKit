//
//  SHKWhatsApp.m
//  ShareKit
//
//  Created by Bernhard Hering on 10.06.14.
//
//
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

#import "SHKWhatsApp.h"
#import "SharersCommonHeaders.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation SHKWhatsApp

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle {	return SHKLocalizedString(@"WhatsApp"); }

+ (BOOL)canShareURL { return YES; }

+ (BOOL)canShareImage { return YES; }

+ (BOOL)canShareText { return YES; }

+ (BOOL)canShareFile:(SHKFile *)file {
    
    if ([[self class] isFileSupportedImage:file] || [[self class] isFileSupportedVideo:file] || [[self class] isFileSupportedAudio:file]) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)shareRequiresInternetConnection
{
	return NO;
}

+ (BOOL)requiresAuthentication
{
	return NO;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

+ (BOOL)canShare
{
	BOOL isWhatsAppInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"whatsapp://send?text=test"]];
	return isWhatsAppInstalled;
}

- (BOOL)shouldAutoShare
{
	return YES;
}

#pragma mark -
#pragma mark Share API Methods

- (BOOL)send
{
    self.quiet = YES;
    
    switch (self.item.shareType) {
        case SHKShareTypeText:
        case SHKShareTypeURL:
        {
            NSString *body = self.item.text;
            
            if (!body)
            {
                body = @"";
            }
            
            if (self.item.title) {
                body = [NSString stringWithFormat:@"%@%@",body,self.item.title];
            }
            
            body= [body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            if (self.item.URL) {
                NSString *urlStr = SHKEncodeURL(self.item.URL);
                body = [NSString stringWithFormat:@"%@%%20%@",body,urlStr];
            }
            
            
            
            // fallback
            if (body == nil)
                body = @"";
            
            body = [NSString stringWithFormat:@"whatsapp://send?text=%@",body];
            
            NSURL *whatsappURL = [NSURL URLWithString:body];
            
            [[UIApplication sharedApplication] openURL: whatsappURL];
            
            [self sendDidFinish];
        }
            break;
        
        case SHKShareTypeImage:
            [self.item convertImageShareToFileShareOfType:SHKImageConversionTypeJPG quality:8];
        case SHKShareTypeFile:
        {
            if ([[self class] isFileSupportedImage:self.item.file]) {
                
                NSString *copyPath = [self.item.file makeTemporaryUIDICCopyWithFileExtension:@"wai"];
                if (!copyPath) return NO;
                [self openInteractionControllerFileURL:[NSURL fileURLWithPath:copyPath] UTI:@"net.whatsapp.image" annotation:nil];
                
            } else if ([[self class] isFileSupportedAudio:self.item.file]) {
                
                NSString *copyPath = [self.item.file makeTemporaryUIDICCopyWithFileExtension:@"waa"];
                if (!copyPath) return NO;
                [self openInteractionControllerFileURL:[NSURL fileURLWithPath:copyPath] UTI:@"net.whatsapp.audio" annotation:nil];
            
            } else {
                
                NSString *copyPath = [self.item.file makeTemporaryUIDICCopyWithFileExtension:@"wam"];
                if (!copyPath) return NO;
                [self openInteractionControllerFileURL:[NSURL fileURLWithPath:copyPath] UTI:@"net.whatsapp.movie" annotation:nil];
            }
        }
            break;
        default:
            break;
    }
	    
    return YES;
}

+ (BOOL)isFileSupportedImage:(SHKFile *)file {
    
    BOOL result = UTTypeConformsTo((__bridge CFStringRef)(file.UTIType), kUTTypeImage);
    return result;
}

+ (BOOL)isFileSupportedVideo:(SHKFile *)file {
    
    BOOL result = UTTypeConformsTo((__bridge CFStringRef)(file.UTIType), kUTTypeMovie);
    return result;
}

+ (BOOL)isFileSupportedAudio:(SHKFile *)file {
    
    BOOL result = UTTypeConformsTo((__bridge CFStringRef)(file.UTIType), kUTTypeAudio);
    return result;
}

@end
