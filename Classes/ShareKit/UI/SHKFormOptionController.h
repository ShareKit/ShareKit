//
//  SHKFormOptionController.h
//  PhotoToaster
//
//  Created by Steve Troppoli on 9/2/11.
//  Copyright 2011 East Coast Pixels. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SHKFormFieldSettings;
@protocol SHKFormOptionControllerClient;
@protocol SHKFormOptionControllerOptionProvider;

@interface SHKFormOptionController : UITableViewController {
	SHKFormFieldSettings* settings;
	id<SHKFormOptionControllerClient> client;
	id<SHKFormOptionControllerOptionProvider> provider;
	bool didLoad;
}

@property(nonatomic,retain) SHKFormFieldSettings* settings;
@property(nonatomic,assign) id<SHKFormOptionControllerClient> client;


- (id)initWithOptionsInfo:(SHKFormFieldSettings*) settingsItem client:(id<SHKFormOptionControllerClient>) optionClient;
- (void) optionsEnumerated:(NSArray*) options;
- (void) optionsEnumerationFailedWithError:(NSError *)error;;
@end




@protocol SHKFormOptionControllerClient

@required
// called when an item is taped or cancel is clicked, cancel passes nil pickedOption.
-(void) SHKFormOptionController:(SHKFormOptionController*) optionController pickedOption:(NSString*)pickedOption;
@end	




@protocol SHKFormOptionControllerOptionProvider

@required
// called when network based options need to be enumerated
// delegates must call either optionsEnumerated: or optionsEnumerationFailedWithError:
-(void) SHKFormOptionControllerEnumerateOptions:(SHKFormOptionController*) optionController;
// called to cancel an enumeration request
-(void) SHKFormOptionControllerCancelEnumerateOptions:(SHKFormOptionController*) optionController;
@end	
