//
//  SHKFormFieldCellTextLarge.h
//  ShareKit
//
//  Created by Vilem Kurz on 30/07/2013.
//
//

#import "SHKFormFieldCell.h"

@interface SHKFormFieldCellTextLarge : SHKFormFieldCell <UITextViewDelegate>

//so that subclasses can override
- (CGRect)frameForTextview;

@end
