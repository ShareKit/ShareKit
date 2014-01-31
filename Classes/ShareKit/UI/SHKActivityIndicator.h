//
//  SHKActivityIndicator.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/16/10.

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

/*!
 @class SHKActivityIndicator
 @discussion Displays HUD with info about status of the sharing process. In case multiple sharers run at once, HUD displays info about the most recent sharer. Previous continue to share silently. 
 */

#import <Foundation/Foundation.h>

@class SHKSharer;

@interface SHKActivityIndicator : UIView

+ (SHKActivityIndicator *)currentIndicator;

- (void)hideForSharer:(SHKSharer *)sharer;
- (void)displayActivity:(NSString *)m forSharer:(SHKSharer *)sharer;
- (void)displayCompleted:(NSString *)m forSharer:(SHKSharer *)sharer;
/*!
 Displays specified progress. Supply range from 0.0 to 1.0.
 */
- (void)showProgress:(CGFloat)progress forSharer:(SHKSharer *)sharer;

#pragma mark - Deprecated methods

- (void)hide __attribute__((deprecated("use hideForSharer: instead")));
- (void)displayActivity:(NSString *)m __attribute__((deprecated("use displayActivity:forSharer: instead")));
- (void)displayCompleted:(NSString *)m __attribute__((deprecated("use displayCompleted:forSharer: instead")));
/*!
 Displays specified progress. Supply range from 0.0 to 1.0.
 */
- (void)showProgress:(CGFloat)progress __attribute__((deprecated("use showProgress:forSharer: instead")));

@end
