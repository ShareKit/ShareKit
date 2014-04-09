//
//  StreamReader.h
//  Live SDK for iOS
//
//  Copyright (c) 2011 Microsoft. All rights reserved.
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
