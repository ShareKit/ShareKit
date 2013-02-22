//
//  ExampleShareVideo.m
//  ShareKit
//
//  Created by Adrian Tofan on 22/02/13.
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


#import "ExampleShareVideo.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SHK.h"
#import "SHKActionSheet.h"
#import "SHKConfiguration.h"
//#define SHKCONFIG(_CONFIG_KEY) [[SHKConfiguration sharedInstance] configurationValue:@#_CONFIG_KEY withObject:nil]



@interface ExampleShareVideo ()
@property (nonatomic,retain) MPMoviePlayerController* moviePlayer;
@end

@implementation ExampleShareVideo

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
      self.toolbarItems = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share)],
                           [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           nil
                           ];
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  if (!self.moviePlayer) {
//    NSString *videoPath   =   [[NSBundle mainBundle] pathForResource:@"demo_video_share" ofType:@"mov"];
    
    NSString *videoPath   =   [[NSBundle mainBundle] pathForResource:@"My First Project" ofType:@"m4v"];

    NSURL    *videoURL    =   [NSURL fileURLWithPath:videoPath];
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    [self.moviePlayer prepareToPlay];
    [self.moviePlayer.view setFrame:CGRectMake(0.0, 50.0, 320.0, 320.0)];
    self.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    [self.view addSubview:self.moviePlayer.view];
  }
}

- (void)share
{
  if ([SHKCONFIG(forcePreIOS6FacebookPosting) boolValue]) {
    NSString *videoPath   =   [[NSBundle mainBundle] pathForResource:@"demo_video_share" ofType:@"mov"];
    SHKItem *item = [SHKItem videoPath:videoPath  title:@"My Awesome Video"];
    item.text = @"test";
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
    [actionSheet showFromToolbar:self.navigationController.toolbar];
  }else{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Video sharing configuration"
                                                    message:@"Video sharing needs forcePreIOS6FacebookPosting = YES"
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}
@end
