//
//  SHKAlertController.m
//  ShareKit
//
//  Created by Vilém Kurz on 22/12/14.
//
//

#import "SHKAlertController.h"
#import "SHK.h"
#import "SHKSharer.h"
#import "SHKConfiguration.h"
#import "SHKShareItemDelegate.h"
#import "SHKShareMenu.h"

@interface SHKAlertController ()

@property (strong) SHKItem *item;
@property (strong) NSMutableArray *sharers;

@end

@implementation SHKAlertController

+ (instancetype)actionSheetForItem:(SHKItem *)item
{
    SHKAlertController *as = [SHKAlertController alertControllerWithTitle:SHKLocalizedString(@"Share") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    as.item = item;
    as.sharers = [as sharersToShow];
    [as populateButtons];
    return as;
}

- (NSMutableArray *)sharersToShow {
    
    NSMutableArray *result = [SHK sharersToShowInActionSheetForItem:self.item];
    return result;
}

- (void)populateButtons {
    
    //add sharer buttons
    for (NSString *sharerId in self.sharers) {

        UIAlertAction *sharerAction = [UIAlertAction actionWithTitle:[NSClassFromString(sharerId) sharerTitle]
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                                                                 
                                                                 bool doShare = YES;
                                                                 SHKSharer* sharer = [[NSClassFromString(sharerId) alloc] init];
                                                                 [sharer loadItem:self.item];
                                                                 if (self.shareDelegate != nil && [self.shareDelegate respondsToSelector:@selector(aboutToShareItem:withSharer:)])
                                                                 {
                                                                     doShare = [self.shareDelegate aboutToShareItem:self.item withSharer:sharer];
                                                                 }
                                                                 if(doShare)
                                                                     [sharer share];
                                                             }];
        
        [self addAction:sharerAction];
    }
    
    if([SHKCONFIG(showActionSheetMoreButton) boolValue])
    {
        // Add More button
        UIAlertAction *moreAction = [UIAlertAction actionWithTitle:SHKLocalizedString(@"More...")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               
                                                               SHKShareMenu *shareMenu = [[SHKCONFIG(SHKShareMenuSubclass) alloc] initWithStyle:UITableViewStyleGrouped];
                                                               shareMenu.shareDelegate = self.shareDelegate;
                                                               shareMenu.item = self.item;
                                                               [[SHK currentHelper] showViewController:shareMenu];

        }];
        [self addAction:moreAction];
    }
    
    // Add Cancel button
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:SHKLocalizedString(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
    [self addAction:cancelAction];
}

@end
