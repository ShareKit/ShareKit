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
 To hide ShareKit specific debug output in the console, undefine _SHKDebugShowLogs (comment line 19). The only useful scenario when you might want to disable debug output is when you want to clean up the console - the ShareKit debug works only in DEBUG builds, thus you do not need to explicitly disable it for RELEASE builds. 
 */

#ifdef DEBUG
#define _SHKDebugShowLogs
#endif

#ifdef _SHKDebugShowLogs
#define SHKDebugShowLogs			1
#define SHKLog( s, ... ) NSLog( @"<%s %@:(%d)> %@", __func__, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define SHKDebugShowLogs			0
#define SHKLog( s, ... )
#endif


#endif
