//
//  Singleton.h
//  ShareKit
//
//  Created by Vilem Kurz on 07/03/2013.
//
//

#define DEFINE_SHARED_INSTANCE_USING_BLOCK(block) \
static dispatch_once_t pred = 0; \
static id _sharedObject = nil; \
dispatch_once(&pred, ^{ \
_sharedObject = block(); \
[_sharedObject retain]; \
}); \
return _sharedObject; \
