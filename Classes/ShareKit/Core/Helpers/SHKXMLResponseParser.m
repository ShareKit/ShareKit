//
//  SHKXMLResponseParser.m
//  ShareKit
//
//  Created by Vilem Kurz on 27.1.2012.
//  Copyright (c) 2012 Cocoa Miners. All rights reserved.
//

#import "SHKXMLResponseParser.h"

@interface SHKXMLResponseParser ()

@property (nonatomic, retain) NSMutableDictionary *parsedResponse;
@property (nonatomic, retain) NSMutableString *currentElementValue;
@property (nonatomic, retain) NSData *data;
@property BOOL xmlParsedSuccessfully;

- (id)initWithData:(NSData *)responseData;
- (void)parse;

@end

@implementation SHKXMLResponseParser

@synthesize parsedResponse, currentElementValue, data, xmlParsedSuccessfully;

- (void)dealloc {
    
    [parsedResponse release];
    [currentElementValue release];
    [data release];
    
    [super dealloc];
}

- (id)initWithData:(NSData *)responseData {
    
    self = [super init];
    
    if (self) {
        data = [responseData retain];        
    }
    return self;
}

+ (NSString *)getValueForElement:(NSString *)element fromResponse:(NSData *)data {
    
    SHKXMLResponseParser *shkParser = [[SHKXMLResponseParser alloc] initWithData:data];
    [shkParser parse];
    
    NSString *result;    
    if (shkParser.xmlParsedSuccessfully) {
        result = [shkParser.parsedResponse objectForKey:element];
    } else {
        result = nil;
    }
    [shkParser release];

    return result;    
}

- (void)parse {
    
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:self.data];
    xmlParser.delegate = self;        
    self.xmlParsedSuccessfully = [xmlParser parse];
}

#pragma mark -
#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict {
    
    self.currentElementValue = nil;
    
    if ([elementName isEqualToString:@"error"]) {        
        
        self.parsedResponse = [NSMutableDictionary dictionaryWithCapacity:0];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (!self.currentElementValue) {
        
        self.currentElementValue = [NSMutableString stringWithString:string];
        
    } else {
        
        [self.currentElementValue appendString:string];
    }    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if(![elementName isEqualToString:@"errors"] && ![elementName isEqualToString:@"error"]) {
        
        NSString *trimmedElementValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        [self.parsedResponse setValue:trimmedElementValue forKey:elementName];
    }
}

@end
