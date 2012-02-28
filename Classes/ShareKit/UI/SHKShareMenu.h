//
//  SHKShareMenu.h
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

#import <UIKit/UIKit.h>
#import "SHK.h"

@protocol SHKShareItemDelegate;

@interface SHKShareMenu : UITableViewController 
{
	SHKItem *item;
	NSMutableArray *tableData;
	NSMutableArray *exclusions;
	id<SHKShareItemDelegate> shareDelegate;
}

@property (nonatomic, retain) SHKItem *item;
@property (retain) NSMutableArray *tableData;
@property (retain) NSMutableArray *exclusions;
@property (retain) id<SHKShareItemDelegate> shareDelegate;


- (void)rebuildTableDataAnimated:(BOOL)animated;
- (NSMutableArray *)section:(NSString *)section;
- (NSDictionary *)rowDataAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark -
#pragma mark Toolbar Buttons

- (void)cancel;
- (void)edit;
- (void)save;



@end
