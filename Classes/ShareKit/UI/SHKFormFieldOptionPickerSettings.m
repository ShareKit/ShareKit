//
//  SHKFormOptionControllerSettings.m
//  ShareKit
//
//  Created by Vilém Kurz on 7/28/13.
//
//

#import "SHKFormFieldOptionPickerSettings.h"
#import "NSArray+JoinValues.h"

@implementation SHKFormFieldOptionPickerSettings

+ (SHKFormFieldOptionPickerSettings *)label:(NSString *)l
                                        key:(NSString *)k
                                      start:(NSString *)s
                                pickerTitle:(NSString *)pickerTitle
                            selectedIndexes:(NSMutableIndexSet *)selectedIndexes
                              displayValues:(NSArray *)displayValues
                                 saveValues:(NSArray *)saveValues
                              allowMultiple:(BOOL)allowMultiple
                               fetchFromWeb:(BOOL)fetchFromWeb
                                   provider:(id <SHKFormOptionControllerOptionProvider>)provider {
    
    SHKFormFieldOptionPickerSettings *result = [[SHKFormFieldOptionPickerSettings alloc] initWithLabel:l key:k type:SHKFormFieldTypeOptionPicker start:s];
    result.pickerTitle = pickerTitle;
    
    if (selectedIndexes) {
        result.selectedIndexes = selectedIndexes;
    } else {
        result.selectedIndexes = [[NSMutableIndexSet alloc] init];
    }
    
    result.displayValues = displayValues;
    
    if (saveValues) {
        NSAssert([saveValues count] == [displayValues count], @"saveValues and displayValues mapping must match");
    }
    result.saveValues = saveValues;
    
    result.allowMultiple = allowMultiple;
    result.fetchFromWeb = fetchFromWeb;
    result.provider = provider;
    
    return result;
}

- (NSString *)valueToSave {
    
    NSArray *decisiveArray = self.saveValues ? self.saveValues : self.displayValues;
    NSString *result = [decisiveArray joinValuesForIndexes:self.selectedIndexes];
    if (!result && self.pushNewContentOnSelection) { //might happen if user pressed done on the first navigationController (i.e. without actually selecting any option - actually picked start value)
        result = self.start;
    }
    return result;

}

- (NSString *)displayValue {
    
    NSString *result;
    if ([self hasSelectedIndexes]) {
        result = [self.displayValues joinValuesForIndexes:self.selectedIndexes];
    } else {
        result = self.start;
    }
    return result;
}

- (BOOL)hasSelectedIndexes {
    
    if ([self.selectedIndexes count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - NSCopying protocol

- (id)copyWithZone:(NSZone *)zone {
    
    SHKFormFieldOptionPickerSettings *result = [SHKFormFieldOptionPickerSettings label:self.label
                                                                                   key:self.key
                                                                                 start:self.start
                                                                           pickerTitle:self.pickerTitle
                                                                       selectedIndexes:[self.selectedIndexes mutableCopy]
                                                                         displayValues:self.displayValues
                                                                            saveValues:self.saveValues
                                                                         allowMultiple:self.allowMultiple
                                                                          fetchFromWeb:self.fetchFromWeb
                                                                              provider:self.provider];
    result.pushNewContentOnSelection = self.pushNewContentOnSelection;
    result.validationBlock = self.validationBlock;
    
    return result;
}

@end
