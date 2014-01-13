//
//  ExampleShareFile.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/29/10.

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

#import "ExampleShareFile.h"

#import "ShareKit.h"
#import "SHK.h"

#define SHARE_FILE_WITH_PATH 1

@interface ExampleShareFile () <UIWebViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *fileTypes;

@end

@implementation ExampleShareFile

- (void)dealloc
{
    _tableView.delegate = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])
	{
        _fileTypes = @[@"PDF", @"Video", @"Audio", @"Image"];
	}
	
	return self;
}

- (void)loadView 
{ 
	self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
	self.tableView.delegate = self;
    self.tableView.dataSource = self;
	self.view = self.tableView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHKItem *item = nil;
    NSError *error = nil;
    
    switch (indexPath.row) {
        case 0:
        {
            NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"example.pdf"];
            
            if (SHARE_FILE_WITH_PATH) {
                item = [SHKItem filePath:filePath title:@"My Awesome PDF"];
            } else {
                NSData *file = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMapped error:&error];
                item = [SHKItem fileData:file filename:@"Awesome.pdf" title:@"My Awesome PDF"];
            }

            break;
        }
        case 1:
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"demo_video_share" ofType:@"mov"];
            
            if (SHARE_FILE_WITH_PATH) {
                item = [SHKItem filePath:filePath title:@"Impressionism - blue ball"];
            } else {
                NSData *file = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMapped error:&error];
                item = [SHKItem fileData:file filename:@"demo_video_share.mov" title:@"Impressionism - blue ball"];
            }
            break;
        }
        case 2:
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"demo_audio_share" ofType:@"mp3"];
            
            if (SHARE_FILE_WITH_PATH) {
                item = [SHKItem filePath:filePath title:@"Demo audio beat"];
            } else {
                NSData *file = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMapped error:&error];
                item = [SHKItem fileData:file filename:@"demo_audio_share.mp3" title:@"Demo audio beat"];
            }
            break;
        }
        case 3:
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sanFran" ofType:@"jpg"];
            
            if (SHARE_FILE_WITH_PATH) {
                item = [SHKItem filePath:filePath title:@"San Francisco"];
            } else {
                NSData *file = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMapped error:&error];
                item = [SHKItem fileData:file filename:@"sanFran.jpg" title:@"San Francisco"];
            }
            break;
        }
        default:
            break;
    }
    
    item.tags = [NSArray arrayWithObjects:@"file share", @"sharekit", nil];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    [SHK setRootViewController:self];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fileTypes count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *reuseIdentifier = @"fileTypeToShare";
    UITableViewCell *result = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (!result) {
        result = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    result.textLabel.text = self.fileTypes[indexPath.row];
    return result;
}

@end
