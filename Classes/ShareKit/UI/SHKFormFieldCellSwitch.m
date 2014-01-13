//
//  SHKFormFieldCellSwitch.m
//  ShareKit
//
//  Created by Vilem Kurz on 31/05/2012.

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

#import "SHKFormFieldCellSwitch.h"
#import "SHKFormFieldSettings.h"

@implementation SHKFormFieldCellSwitch

@synthesize mySwitch;


- (void)setupLayout {
    
    UISwitch *aSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [aSwitch addTarget:self action: @selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    self.mySwitch = aSwitch;
    self.accessoryView = self.mySwitch;     
    
    [super setupLayout];    
}

- (void)setupWithSettings:(SHKFormFieldSettings *)settings {
    
    self.textLabel.text = settings.label;
    
    if ([settings.displayValue isEqualToString:SHKFormFieldSwitchOn]) {
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
