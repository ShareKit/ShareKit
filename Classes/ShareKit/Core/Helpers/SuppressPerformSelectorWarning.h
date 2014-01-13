//
//  SuppressPerformSelectorWarning.h
//  ShareKit
//
//  Created by Vilem Kurz on 04/07/2013.
//
//

#ifndef ShareKit_SuppressPerformSelectorWarning_h
#define ShareKit_SuppressPerformSelectorWarning_h

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

#endif
