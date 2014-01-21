//
//  SHKFormOptionController.h
//  PhotoToaster
//
//  Created by Steve Troppoli on 9/2/11.
//  Copyright 2011 East Coast Pixels. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SHKFormFieldSettings;
@class SHKFormFieldOptionPickerSettings;

@protocol SHKFormOptionControllerClient;
@protocol SHKFormOptionControllerOptionProvider;

@interface SHKFormOptionController : UITableViewController

@property (nonatomic, readonly) SHKFormFieldOptionPickerSettings *settings;

///used if pushContentOnSelection is true. Provider uses this value to fetch content for selection.
@property (nonatomic, strong) NSString *selectionValue;

- (id)initWithOptionPickerSettings:(SHKFormFieldOptionPickerSettings *)settingsItem client:(id <SHKFormOptionControllerClient>)optionClient;

- (void)optionsEnumeratedDisplay:(NSArray *)displayOptions save:(NSArray *)saveOptions;
- (void)optionsEnumerationFailedWithError:(NSError *)error;

@end

@protocol SHKFormOptionControllerClient

@required
// called when an item is taped or cancel is clicked, cancel passes nil pickedOption.
- (void)SHKFormOptionControllerDidFinish:(SHKFormOptionController *)optionController;

@end

@protocol SHKFormOptionControllerOptionProvider

@required
// called when network based options need to be enumerated
// delegates must call either optionsEnumerated: or optionsEnumerationFailedWithError:
-(void) SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController*) optionController;
// called to cancel an enumeration request
-(void) SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController*) optionController;
@end	
