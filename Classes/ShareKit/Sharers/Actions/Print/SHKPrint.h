#import <Foundation/Foundation.h>
#import "SHKSharer.h"

#define PRINT_INFO_OUTPUT_TYPE_KEY @"PrintInfoOutputTypeKey"

#define PRINT_INFO_OUTPUT_TYPE_VALUE_GENERAL @"PrintInfoOutputTypeValueGeneral"
#define PRINT_INFO_OUTPUT_TYPE_VALUE_PHOTO @"PrintInfoOutputTypeValuePhoto"
#define PRINT_INFO_OUTPUT_TYPE_VALUE_GRAYSCALE @"PrintInfoOutputTypeValueGrayscale"

@interface SHKPrint : SHKSharer

- (BOOL)print;

@end
