//
//  SHKAlertController.h
//  ShareKit
//
//  Created by Vilém Kurz on 22/12/14.
//
//

#import <UIKit/UIKit.h>

@protocol SHKShareItemDelegate;
@class SHKItem;

@interface SHKAlertController : UIAlertController

@property (strong) id<SHKShareItemDelegate> shareDelegate;

+ (instancetype)actionSheetForItem:(SHKItem *)i;

- (NSMutableArray *)sharersToShow;
- (void)populateButtons;

@end
