//
//  Debug.h
//  ShareKit
//
//  Created by Vilém Kurz on 7/2/13.
//
//

#ifndef ShareKit_Debug_h
#define ShareKit_Debug_h

/*
 Debugging
 ------
 To show ShareKit specific debug output in the console, define _SHKDebugShowLogs (uncomment next line).
 */

#define _SHKDebugShowLogs

#ifdef _SHKDebugShowLogs
#define SHKDebugShowLogs			1
#define SHKLog( s, ... ) NSLog( @"<%s %@:(%d)> %@", __func__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define SHKDebugShowLogs			0
#define SHKLog( s, ... )
#endif


#endif
