//
//  SHKUploadData.h
//  ShareKit
//
//  Created by Vilém Kurz on 27/01/14.
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

#import <Foundation/Foundation.h>

@class SHKSharer;

@interface SHKUploadInfo : NSObject <NSCoding>

///The uploading sharer
@property (weak) SHKSharer *sharer;
@property (copy) NSString *sharerTitle;
@property (copy) NSString *filename;

///upload total size
@property int64_t bytesTotal;
@property int64_t bytesUploaded;

///YES, if upload finished successfully
@property BOOL uploadFinishedSuccessfully;

///YES if user cancelled the share in SHKUploadsViewController
@property BOOL uploadCancelled;

- (instancetype)initWithSharer:(SHKSharer *)sharer;

///Returns YES, if upload is failed.
- (BOOL)isFailed;
- (BOOL)isInProgress;

///percentage, from 0.0 to 1.0
- (CGFloat)uploadProgress;

@end
