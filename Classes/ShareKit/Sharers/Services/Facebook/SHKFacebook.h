//
//  SHKFacebook.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/18/10.
//	3.0 SDK rewrite - Steven Troppoli 9/25/2012

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
#import "SHKSharer.h"

@interface SHKFacebook : SHKSharer

@property (readonly,strong) NSMutableSet* pendingConnections; // sub classes can use the set. use a set so that connections can only be added once

+ (BOOL)handleOpenURL:(NSURL*)url;
+ (void)handleDidBecomeActive;
+ (void)handleWillTerminate;

// override point for subclasses that want to do something interesting while sending non-nativly
- (void)doSend;
// keep in mind of you add requests as a subclass, you need to cancel them yourself and remove
// them from the pending set. The base version will cancel anything that responds to the cancel selector
- (void)cancelPendingRequests;
@end
