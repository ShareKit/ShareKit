/*
 Copyright (C) 2009 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*!
 *  This file was modified to avoid namespace collisions for different versions
 *  of JSON. Ex. FB framework and DB framework use the similar JSON with same
 *  JSON.h
 *  DBJSON* were moved from Dropbox SDK root folder and overriden to aviod the
 *  same issue.
 *  See more detail on http://stackoverflow.com/questions/178434/what-is-the-best-way-to-solve-an-objective-c-namespace-
 *  Valery Nikitin (submarine). Mistral LLC on 10/2/12.
 */

#import <Foundation/Foundation.h>

extern NSString * DBJSONErrorDomain;


typedef enum {
    DB_EUNSUPPORTED = 1,
    DB_EPARSENUM,
    DB_EPARSE,
    DB_EFRAGMENT,
    DB_ECTRL,
    DB_EUNICODE,
    DB_EDEPTH,
    DB_EESCAPE,
    DB_ETRAILCOMMA,
    DB_ETRAILGARBAGE,
    DB_EEOF,
    DB_EINPUT
} DBJSONErrorDomainEnum;

/**
 @brief Common base class for parsing & writing.

 This class contains the common error-handling code and option between the parser/writer.
 */
@interface DBJsonBase : NSObject {
    NSMutableArray *errorTrace;

@protected
    NSUInteger depth, maxDepth;
}

/**
 @brief The maximum recursing depth.
 
 Defaults to 512. If the input is nested deeper than this the input will be deemed to be
 malicious and the parser returns nil, signalling an error. ("Nested too deep".) You can
 turn off this security feature by setting the maxDepth value to 0.
 */
@property NSUInteger maxDepth;

/**
 @brief Return an error trace, or nil if there was no errors.
 
 Note that this method returns the trace of the last method that failed.
 You need to check the return value of the call you're making to figure out
 if the call actually failed, before you know call this method.
 */
 @property(copy,readonly) NSArray* errorTrace;

/// @internal for use in subclasses to add errors to the stack trace
- (void)addErrorWithCode:(NSUInteger)code description:(NSString*)str;

/// @internal for use in subclasess to clear the error before a new parsing attempt
- (void)clearErrorTrace;

@end
