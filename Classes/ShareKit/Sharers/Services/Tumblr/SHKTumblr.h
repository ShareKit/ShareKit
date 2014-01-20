//
//  SHKTumblr.h
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

/*
 Optional SHKItem properties accepted by SHKTumblr beyond default for each sharer:
 
 all share types: tags
 
 SHKShareTypeText:title (as Title)
 
 SHKShareTypeURL:text (as Description)). You can use SHKURLContentTypeAudio, Video, Image, Webpage, all will be displayed correctly (embedded video player etc).
 
 SHKShareTypeImage:
 
 SHKShareTypeFile: accepted mimeTypes are image/ video/ audio/. Each is shared so that Tumblr displays it properly - video in player etc. If you share photo as a file, exif info is preserved. Unfortunately files are loaded to memory in the moment of sharing, so be careful with large files.
 */

#import <Foundation/Foundation.h>
#import "SHKOAuthSharer.h"
#import "SHKFormOptionController.h"

extern NSString * const kSHKTumblrUserInfo;

@interface SHKTumblr : SHKOAuthSharer <SHKFormOptionControllerOptionProvider>

@end
