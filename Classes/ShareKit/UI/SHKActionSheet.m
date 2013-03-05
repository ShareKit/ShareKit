//
//  SHKActionSheet.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/10/10.

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

#import "SHKActionSheet.h"
#import "SHKShareMenu.h"
#import "SHK.h"
#import "SHKConfiguration.h"
#import "SHKSharer.h"
#import "SHKShareItemDelegate.h"

#import <Foundation/NSObjCRuntime.h>

@implementation SHKActionSheet

- (void)dealloc
{
	[_item release];
	[_sharers release];
	[_shareDelegate release];
	[super dealloc];
}

+ (SHKActionSheet *)actionSheetForItem:(SHKItem *)item
{
	SHKActionSheet *as = [[SHKCONFIG(SHKActionSheetSubclass) alloc] initWithTitle:SHKLocalizedString(@"Share")
													  delegate:nil
											 cancelButtonTitle:nil
										destructiveButtonTitle:nil
											 otherButtonTitles:nil];
	as.delegate = as;
	as.item = item;
	
	as.sharers = [NSMutableArray arrayWithCapacity:0];
	NSArray *favoriteSharers = [SHK favoriteSharersForItem:item];
		
	// Add buttons for each favorite sharer
	id class;
	for(NSString *sharerId in favoriteSharers)
	{
		//Do not add buttons for sharers, which are not able to share item
        class = NSClassFromString(sharerId);
		if ([class canShare] && [class canShareItem:item])
		{
			[as addButtonWithTitle: [class sharerTitle] ];
			[as.sharers addObject:sharerId];
		}
	}
	
	if([SHKCONFIG(showActionSheetMoreButton) boolValue])
	{
		// Add More button
		[as addButtonWithTitle:SHKLocalizedString(@"More...")];
	}
	
	// Add Cancel button
	[as addButtonWithTitle:SHKLocalizedString(@"Cancel")];
	as.cancelButtonIndex = as.numberOfButtons -1;
	
	return [as autorelease];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    NSInteger numberOfSharers = (NSInteger) [_sharers count];

	// Sharers
	if (buttonIndex >= 0 && buttonIndex < numberOfSharers)
	{
		bool doShare = YES;
		SHKSharer* sharer = [[[NSClassFromString([self.sharers objectAtIndex:buttonIndex]) alloc] init] autorelease];
		[sharer loadItem:self.item];
		if (self.shareDelegate != nil && [self.shareDelegate respondsToSelector:@selector(aboutToShareItem:withSharer:)])
		{
			doShare = [self.shareDelegate aboutToShareItem:self.item withSharer:sharer];
		}
		if(doShare)
			[sharer share];
	}
	
	// More
	else if ([SHKCONFIG(showActionSheetMoreButton) boolValue] && buttonIndex == numberOfSharers)
	{
		SHKShareMenu *shareMenu = [[SHKCONFIG(SHKShareMenuSubclass) alloc] initWithStyle:UITableViewStyleGrouped];
		shareMenu.shareDelegate = self.shareDelegate;
		shareMenu.item = self.item;
		[[SHK currentHelper] showViewController:shareMenu];
		[shareMenu release];
	}
	
	[super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

@end
