//
//  SHKFormFieldCellSwitch.m
//  ShareKit
//
//  Created by Vilem Kurz on 31/05/2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "SHKFormFieldCellSwitch.h"

@implementation SHKFormFieldCellSwitch

@synthesize mySwitch;

- (void)dealloc {
    
    [mySwitch release];
    [super dealloc];
}

- (void)setupLayout {
    
    UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [aSwitch addTarget:self action: @selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    self.mySwitch = aSwitch;
    [aSwitch release];
    self.accessoryView = self.mySwitch;     
    
    [super setupLayout];    
}

- (void)setupWithSettings:(SHKFormFieldSettings *)settings {
    
    self.textLabel.text = settings.label;
    
    if ([settings.value isEqualToString:SHKFormFieldSwitchOn]) {
        self.mySwitch.on = YES;        
    } else {        
        self.mySwitch.on = NO;
    }   
        
    [super setupWithSettings:settings];
}

- (void)switchChange:(UISwitch *)sender {
    
    if (sender.on) {
        
        [self userSetValue:SHKFormFieldSwitchOn];
        
    } else {
        
        [self userSetValue:SHKFormFieldSwitchOff];
    }
}

@end
