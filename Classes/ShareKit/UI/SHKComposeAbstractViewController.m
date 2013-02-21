//
//  SHKComposeAbstractViewController.m
//  ShareKit
//
//  Created by Euan Lau on 12/11/12.
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

#import "SHKComposeAbstractViewController.h"
#import "SHK.h"
#import "SHKConfiguration.h"

@interface SHKComposeAbstractViewController ()

@end

@implementation SHKComposeAbstractViewController

@synthesize delegate = _delegate;
@synthesize maxTextLength = _maxTextLength;
@synthesize imageTextLength = _imageTextLength;
@synthesize allowSendingEmptyMessage = _allowSendingEmptyMessage;
@synthesize hasLink = _hasLink;
@synthesize text = _text;
@synthesize image = _image;

+ (SHKComposeAbstractViewController *)controllerForSharerClass:(Class)sharerClass
{
  return [[[SHKCONFIG_WITH_ARGUMENT(SHKComposeControllerForSharerClass:,sharerClass) alloc]
           initWithNibName:nil bundle:nil] autorelease];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
	{
    _maxTextLength = 0;
    _imageTextLength = 0;
    _allowSendingEmptyMessage = NO;
    _hasLink = NO;
	}
	return self;
}

- (void)dealloc
{
  _delegate = nil;
  [_text release];
  [_image release];
  [super dealloc];
}


@end
