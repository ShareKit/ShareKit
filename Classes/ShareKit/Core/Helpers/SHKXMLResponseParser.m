//
//  SHKXMLResponseParser.m
//  ShareKit
//
//  Created by Vilem Kurz on 27.1.2012.
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "SHKXMLResponseParser.h"

@interface SHKXMLResponseParser ()

@property (nonatomic, strong) NSMutableDictionary *parsedResponse;
@property (nonatomic, strong) NSMutableString *currentElementValue;
@property (nonatomic, strong) NSData *data;
@property BOOL xmlParsedSuccessfully;

- (id)initWithData:(NSData *)responseData;
- (void)parse;
- (NSString *)findRecursivelyValueForKey:(NSString *)searchedKey inDict:(NSDictionary *)dictionary;

@end

@implementation SHKXMLResponseParser

@synthesize parsedResponse, currentElementValue, data, xmlParsedSuccessfully;


- (id)initWithData:(NSData *)responseData {
    
    self = [super init];
    
    if (self) {
        data = responseData;        
    }
    return self;
}

+ (NSString *)getValueForElement:(NSString *)element fromResponse:(NSData *)data {
    
    SHKXMLResponseParser *shkParser = [[SHKXMLResponseParser alloc] initWithData:data];
    [shkParser parse];
    
    NSString *result;    
    if (shkParser.xmlParsedSuccessfully) {
        result = [shkParser findRecursivelyValueForKey:element inDict:shkParser.parsedResponse];
    } else {
        result = nil;
    }

    return result;    
}

- (NSString *)findRecursivelyValueForKey:(NSString *)searchedKey inDict:(NSDictionary *)dictionary {
    
    __block NSString *result = nil;
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        
        if ([key isEqualToString:searchedKey]) {
            result = obj;
            *stop = YES;
            
        } else if ([obj isKindOfClass:[NSDictionary class]]) {
            result = [self findRecursivelyValueForKey:searchedKey inDict:obj];           
            
        }
    }];
    
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
    
    if (!self.parsedResponse) {
        self.parsedResponse = [NSMutableDictionary dictionaryWithCapacity:0];
    } 
    
    if (attributeDict) {
        [self.parsedResponse setObject:attributeDict forKey:elementName];
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
        if (trimmedElementValue) {
            [self.parsedResponse setValue:trimmedElementValue forKey:elementName];
        }        
    }
}

@end
