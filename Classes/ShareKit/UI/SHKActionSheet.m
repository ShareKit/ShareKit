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

@interface SHKActionSheet ()

@property (strong) NSMutableArray *sharers;
@property (strong) SHKItem *item;

@end

@implementation SHKActionSheet

- (instancetype)initWithItem:(SHKItem *)item {
    
    self = [super initWithTitle:SHKLocalizedString(@"Share")
                       delegate:nil
              cancelButtonTitle:nil
         destructiveButtonTitle:nil
              otherButtonTitles:nil, nil];
    
    if (self) {
        _item = item;
    }
    return self;
}

+ (instancetype)actionSheetForItem:(SHKItem *)item
{
	SHKActionSheet *as = [[self alloc] initWithItem:item];
	as.delegate = as;
	as.sharers = [as sharersToShow];
    [as populateButtons];
    return as;
}

- (NSMutableArray *)sharersToShow {
    
    NSMutableArray *result = [SHK sharersToShowInActionSheetForItem:self.item];
    return result;    
}

- (void)populateButtons {
    
    for (NSString *sharerId in self.sharers) {
        [self addButtonWithTitle: [NSClassFromString(sharerId) sharerTitle]];
    }
    
	if([SHKCONFIG(showActionSheetMoreButton) boolValue])
	{
		// Add More button
		[self addButtonWithTitle:SHKLocalizedString(@"More...")];
	}
	
	// Add Cancel button
	[self addButtonWithTitle:SHKLocalizedString(@"Cancel")];
	self.cancelButtonIndex = self.numberOfButtons -1;
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    NSInteger numberOfSharers = (NSInteger) [_sharers count];

	// Sharers
	if (buttonIndex >= 0 && buttonIndex < numberOfSharers)
	{
		bool doShare = YES;
		SHKSharer* sharer = [[NSClassFromString([self.sharers objectAtIndex:buttonIndex]) alloc] init];
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
	}
	
	[super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

@end
