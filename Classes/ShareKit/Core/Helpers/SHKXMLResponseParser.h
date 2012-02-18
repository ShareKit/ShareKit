//
//  SHKXMLResponseParser.h
//  ShareKit
//
//  Created by Vilem Kurz on 27.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHKXMLResponseParser : NSObject <NSXMLParserDelegate>

+ (NSString *)getValueForElement:(NSString *)element fromResponse:(NSData *)data;

@end
