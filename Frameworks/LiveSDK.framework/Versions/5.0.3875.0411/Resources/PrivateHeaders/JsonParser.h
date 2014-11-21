// 
//  JsonParser.h
//  Live SDK for iOS
//
// Copyright 2014 Microsoft Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 
#import <Foundation/Foundation.h>


// ------------------------------------------------------------------------
// MSJSONParser
//
// This class implements a full-featured JSON text parser. The simplest use of this class
// is just calling the class method 'parseText:error:' which will parse the passed JSON
// text and return the root object as the result (returning nil and the error value if an
// error occurred). Optionally, the caller can separately create the parser and call the
// 'parse' method.
//
// By default, the parser creates NSMutableArray objects for each "collection" and
// NSMutableDictionary objects for each "object" in the JSON text. These defaults can
// be overridden by setting the 'collectionClass' and 'objectClass' properties.
//
// The Collection class must either support 'addJSONObject:' to add JSON values
// to the collection or the more generic 'addObject:' (so that you can use standard
// collections like NSMutableArray NSMutableSet without any special changes).
//
// The Object class must either support 'setJSONValue:forMemberName:' or standard
// Key-Value Coding (KVC) semantics (e.g. setValue:forKey:) to set any of the member
// attributes that are found.
//
// The object classes for member names (which are always strings) and string values
// can also be customized by subclassing this class and overriding the
// 'memberNameForString:' and 'valueForStringValue:' methods, respectively. These
// hooks make it possible to do things like remap member names, return canonical
// string objects for member names, or use custom value types for string values
// that represent something else (like dates).
//
// By default, the parser will automatically skip any standard JavaScript comments -
// both single-line (// ... \n) and multi-line (/* ... */) comments are supported.
// Comments are not strictly supported in the JSON standard, so this behavior can
// be disabled by setting the skipJavascriptComments property to NO.
//
// An alternative "JSON light" syntax is also supported (though not used by default).
// This syntax allows two additional string value formats. Light strings are enclosed
// in single quotes (') and don't support embedded escape characters. Identifier
// strings don't need to be quoted at all. They must begin with legal identifier
// starting characters (_, a-z, A-Z) and can only contain only legal identifier
// characters (_, ., 0-9, a-z, A-Z).
// ------------------------------------------------------------------------

@interface MSJSONParser : NSObject
{
	NSScanner                      *_scanner;
	NSError                        *_error;
	BOOL                            _skipJavascriptComments;
	BOOL                            _supportJSONLight;
	Class                           _collectionClass;
	Class                           _objectClass;
}

+ (id) parseText:(NSString*)text error:(NSError**)error;
+ (id) parseJSONLightText:(NSString*)text error:(NSError**)error;

- (id) initWithText:(NSString*)text;
- (id) parse;

@property (readwrite, retain) NSError *error;
@property (readwrite, assign) BOOL skipJavascriptComments;
@property (readwrite, assign) BOOL supportJSONLight;
@property (readwrite, retain) Class collectionClass;       // NSMutableArray by default
@property (readwrite, retain) Class objectClass;           // NSMutableDictionary by default

- (NSString*) memberNameForString:(NSString*)name;   // returns 'name' by default
- (id) valueForStringValue:(NSString*)value;         // returns 'value' by default

@end



// ------------------------------------------------------------------------
// MSJSON_Extensions
//
// This category defines a set of optional methods that objects can choose to
// implement to build extended support for type-specific schema validation.
// (See comments for MSJSONParser for more details on how these calls are
// used.)

@interface NSObject (MSJSON_Extensions)

// Optional collection class object add method
- (void) addJSONObject:(id)value;

// Optional object class JSON member value setter method
- (void) setJSONValue:(id)value forMemberName:(NSString*)memberName;

@end



// ------------------------------------------------------------------------
// NSDate extensions
//
// There is a somewhat broadly accepted "standard" for representing date values in JSON.
// The standard specifies that the string should contain "/Date(###)/" where ### is an
// integer value representing the number of milliseconds since the epoch of 1/1/1970 (UTC).

@interface NSDate (MSJSON_Extensions)
+ (id) dateWithJSONStringValue:(NSString*)value;
@end



// ------------------------------------------------------------------------
// Error information for MSJSON

extern NSString * const MSJSONParserErrorDomain;  // for use with NSError.
extern NSString * const MSJSONParserInternalExceptionKey;  // used in NSError userInfo for unknown exception errors

typedef enum _MSJSONParseError
{
	MSJSONErrorUnknown = 0,
	MSJSONErrorOutOfMemory = 1,
	MSJSONErrorUnexpectedEndOfText = 2,
	MSJSONErrorValueExpected = 3,
	MSJSONErrorStringValueExpected = 4,
	MSJSONErrorIllegalStringEscape = 5,
	MSJSONErrorIllegalStringUnicodeEscape = 6,
	MSJSONErrorSeparatorExpected = 7,
	MSJSONErrorNameSeparatorExpected = 8,
	MSJSONErrorTextAfterRootValue = 9,
	
	MSJSONErrorUnknownException = 512,
} MSJSONParseError;
