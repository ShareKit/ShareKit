//
//  SHKFormFieldCell.h
//  ShareKit
//
//  Created by Nathan Weiner on 6/17/10.

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

#import <UIKit/UIKit.h>
#import "SHK.h"


#define SHK_FORM_CELL_PAD_LEFT 10
#define SHK_FORM_CELL_PAD_RIGHT 10

@class SHKFormController;
@class SHKFormFieldSettings;

@protocol SHKFormFieldCellDelegate <NSObject>

- (void)setActiveTextField:(UITextField *)activeTextField;
- (void)valueChanged;

@end

@interface SHKFormFieldCell : UITableViewCell 

@property (weak) id <SHKFormFieldCellDelegate> delegate;

- (void)setupLayout;
- (void)setupWithSettings:(SHKFormFieldSettings *)_settings;
- (void)userSetValue:(NSString *)newValue;

@end
