//
//  StreamReader.h
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

@protocol StreamReaderDelegate <NSObject>

- (void)streamReadingCompleted:(NSData *)data;
- (void)streamReadingFailed:(NSError *)error;

@end

@interface StreamReader : NSObject<NSStreamDelegate>

@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) NSInputStream *stream;
@property (nonatomic, assign) id<StreamReaderDelegate> delegate;

- (id)initWithStream:(NSInputStream *)stream
            delegate:(id<StreamReaderDelegate>)delegate;

- (void)start;

@end
