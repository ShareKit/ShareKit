//
//  SHKFormFieldCellText.h
//  ShareKit
//
//  Created by Vilem Kurz on 30/05/2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "SHKFormFieldCell_PrivateProperties.h"

@interface SHKFormFieldCellText : SHKFormFieldCell <UITextFieldDelegate>

@property (nonatomic, retain) UITextField *textField;

@end
