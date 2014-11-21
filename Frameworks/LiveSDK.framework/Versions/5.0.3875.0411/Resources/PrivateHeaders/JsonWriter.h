// 
//  JsonWriter.h
//  Live SDK for iOS
//
//  Copyright 2014 Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
// 

#import <Foundation/Foundation.h>


extern NSString * const MSJSONWriterCycleException;


// ------------------------------------------------------------------------
// MSJSONWriter
//
// This class encapsulates the logic to generate a JSON text string for a given value.
// Typically callers will only need to use the class method 'textForValue:' to generate
// a complete JSON text document for a given object value, but additional customization
// is available by subclassing this class and/or calling individual methods directly.
// If this value contains cycles (e.g. objects/collections that reference parent
// objects/collections in the object hierarchy) then an exception will be thrown.
//
// The following rules are used to determine how to generate JSON text for a value,
// in order of preference:
//
//  - If the value responds to 'JSONDescription' then the result of that call is used
//    as the JSON text for that value. This allows clients to completely customize the
//    behavior of any custom classes. An implementation of 'JSONDescription' is provided
//    for the following Cocoa classes: NSNull, NSNumber (including booleans), and NSDate.
//
//  - (Optional) Clients can provide an optional method selector that should match the
//    method signature for 'JSONMemberKeys' and will be used in the same way (see below).
//    This allows clients to customize the behavior of a specific MSJSONWriter instance
//    without overriding behavior for all writers. One common usage of this would be
//    generating custom JSON keys for generic NSDictionary objects without overriding
//    the behavior for all NSDictionaries in the process. This optional selector can
//    be set by setting the memberKeysSelector property.
//
//  - If the value responds to 'JSONMemberKeys' then this method should return either a
//    dictionary with KVC key names as keys and resulting JSON member names as values
//    (members will be written in an arbitrary order), or an enumerable collection
//    (e.g. array or set) of KVC key names that will be also used as JSON member names.
//    The result will be represented as a JSON object with the specified members.
//    Values for each property will follow this same set of rules.
//
//  - If the value responds to 'allKeys' (such as an NSDictionary) then this array of
//    key values is used as the member name "schema" as above.
//
//  - If the value conforms to the NSFastEnumeration protocol then it is assumed to be
//    a collection and will be represented in the JSON as an array. Standard Cocoa
//    collection types (such as NSArray and NSSet) support this protocol. Values in the
//    collection will follow this same set of rules.
//
//  - Finally, 'description' will be called on the value and the result will be returned
//    as a JSON string value (including JSON string escapes, etc.). NSString values
//    always return themselves as the 'description'.
//
// The class method 'escapeStringValue:' can be used as a utility function to generate
// properly escaped JSON text (this is used internally for member names and objects
// that return their value via 'description'). The result string will not be enclosed
// in quotes.
// ------------------------------------------------------------------------

@interface MSJSONWriter : NSObject
{
@private
	NSMutableString                *_text;
	id                              _root;
	id                              _rootSchema;
	NSMutableArray                 *_objectStack;
	SEL                             _memberKeysSelector;
@protected
	NSUInteger                      _indentLevel;
}

+ (NSString*) textForValue:(id)value;
+ (NSString*) escapeStringValue:(NSString*)value;

// This class is initialized with the object that JSON text will be generated for.
// The 'memberInfo:' variant allows a member schema to be specified for the
// specified value (which must be an "object" value).  This schema should follow
// the same conventions as the return value from 'JSONMemberKeys' (and if it is
// specified, then JSONMemberKeys will not be called on the root object value).
- (id) initWithValue:(id)value;
- (id) initWithValue:(id)value memberInfo:(id)schema;

// This method generates and returns the JSON text for the object value specified
// in the initializer. If called multiple times, the generation will only happen
// once (the result is cached), so if the value is changed after this method is
// called a new Writer should be created to generate JSON text that reflects those
// changes.
- (NSString*) JSONText;

@property (readwrite, assign) SEL memberKeysSelector;

@end


// ------------------------------------
// The methods in the JFXJSONWriter_Overrides category are not intended to be used by
// clients of this class, only used and overridden (as needed) by subclasses of MSJSONWriter.

@interface MSJSONWriter (JFXJSONWriter_Overrides)

- (void) pushIndentLevel;
- (void) popIndentLevel;
- (void) appendNewLine;

- (void) appendText:(NSString*)text;

- (void) appendValue:(id)value;
- (void) appendStringValue:(NSString*)value;
- (void) appendObject:(id)value withMemberInfo:(id)schema;
- (void) appendObjectProperty:(id)value withMemberName:(NSString*)memberName;
- (void) appendCollection:(id)value;

@end



// ------------------------------------------------------------------------
// MSJSONWriter_Extensions

// ------------------------------------
// The NSObject extensions are informal protocol definitions that can be implemented
// by classes in order to control the JSON text that will be produced for a given
// class or customize which member keys will be written for a JSON object.

@interface NSObject (MSJSONWriter_Extensions)
- (NSString*) JSONDescription;
- (id) JSONMemberKeys;
@end

// ------------------------------------
// NSDate, NSNumber, and NSNull have support implemented for JSONDescription
// here so that these object types can be used without customization.
//
// Note: NSNumber does not provide an easy way to differentiate between a boolean
// value and any other numeric type. A client that defines a class with a property
// of type 'BOOL' will actually return an NSNumber value that is initialized with an
// integer from standard KVC semantics. If it is important to ensure that a boolean
// value ("true"/"false") is used as the JSON value then object holding this boolean
// property must ensure that 'valueForKey:' returns a value created using
// [NSNumber numberWithBool:<val>].

@interface NSDate (MSJSONWriter_Extensions)
- (NSString*) JSONDescription;
@end

@interface NSNumber (MSJSONWriter_Extensions)
- (NSString*) JSONDescription;
@end

@interface NSNull (MSJSONWriter_Extensions)
- (NSString*) JSONDescription;
@end

