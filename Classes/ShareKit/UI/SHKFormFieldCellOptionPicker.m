//
//  SHKFormFieldCellOptions.m
//  ShareKit
//
//  Created by Vilem Kurz on 31/05/2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "SHKFormFieldCellOptionPicker.h"
#import "SHKConfiguration.h"

@implementation SHKFormFieldCellOptionPicker

- (void)setupLayout {
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    [super setupLayout];
}

- (void)setupWithSettings:(SHKFormFieldSettings *)settings {
  
    self.textLabel.text = settings.label;    
    
    self.detailTextLabel.text = settings.value ? settings.value : settings.optionDetailLabelDefault;
    
    [super setupWithSettings:settings];  
}

@end
