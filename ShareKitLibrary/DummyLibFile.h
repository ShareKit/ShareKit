//
//  DummyLibFile.h
//  ShareKit
//
//  Created by Vilém Kurz on 11/20/12.
//
//

/* the only purpose of this file is to force "global" Static Library (libShareKit) to build. It seems, that it is not possible to build a static library without source files. libShareKit is aggregating all of the granular targets. Global static library is easy to implement, and adds a bonus when new sharers are added, all you need to do is pull, and you have them in your project. */

#import <Foundation/Foundation.h>

@interface DummyLibFile : NSObject

@end
