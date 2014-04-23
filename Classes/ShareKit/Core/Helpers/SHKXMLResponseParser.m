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
#import "NSDictionary+Recursive.h"

@interface SHKXMLResponseParser ()

@property (nonatomic, strong) NSMutableDictionary *parsedResponse;
@property (nonatomic, strong) NSMutableArray *currentElementNames;
@property (nonatomic, strong) NSMutableDictionary *currentParentElement;
@property (nonatomic, strong) NSMutableString *currentElementValue;
@property (nonatomic, strong) NSData *data;
@property BOOL xmlParsedSuccessfully;

@end

@implementation SHKXMLResponseParser

+ (id)getValueForElement:(NSString *)element fromXMLData:(NSData *)data {
    
    SHKXMLResponseParser *shkParser = [[SHKXMLResponseParser alloc] initWithData:data];
    [shkParser parse];
    
    id result;
    if (shkParser.xmlParsedSuccessfully) {
        result = [shkParser.parsedResponse findRecursivelyValueForKey:element];
    } else {
        result = nil;
    }

    return result;    
}

+ (NSDictionary *)dictionaryFromData:(NSData *)data {
    
    SHKXMLResponseParser *shkParser = [[SHKXMLResponseParser alloc] initWithData:data];
    [shkParser parse];
    
    NSDictionary *result = nil;
    if (shkParser.xmlParsedSuccessfully) {
        result = shkParser.parsedResponse;
    }
    return result;
}

- (id)initWithData:(NSData *)responseData {
    
    self = [super init];
    
    if (self) {
        _data = responseData;
        _currentElementNames = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return self;
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
    
    if (!self.parsedResponse) {
        self.parsedResponse = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    
    //if lastElement is not finished, create container - will be subsequently filled with coming elements
    NSString *parentName = [self.currentElementNames lastObject];
    NSDictionary *parentsParent = [self parentOfElement:parentName];
    BOOL elementsParentExists;
    if (parentsParent) {
        elementsParentExists = parentsParent[parentName] != nil;
    } else {
        elementsParentExists = self.parsedResponse[parentName] != nil;
    }
    if ([self.currentElementNames count] > 0 && !elementsParentExists) {
        NSMutableDictionary *lastLevelDict = [NSMutableDictionary dictionaryWithCapacity:3];
        
        if (self.currentParentElement) {
            [self.currentParentElement setObject:lastLevelDict forKey:[self.currentElementNames lastObject]];
        } else {
            [self.parsedResponse setObject:lastLevelDict forKey:[self.currentElementNames lastObject]];
        }
        
        self.currentParentElement = lastLevelDict;
    }
    [self.currentElementNames addObject:elementName];
    
    if ([attributeDict count]) {
        
        NSMutableDictionary *mutableAttributesDict = [attributeDict mutableCopy];
        if (self.currentParentElement) {
            [self.currentParentElement setObject:mutableAttributesDict forKey:elementName];
        } else {
            [self.parsedResponse setObject:mutableAttributesDict forKey:elementName];
        }
        self.currentParentElement = mutableAttributesDict;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (!string) return;
    
    //append or create current element value
    if (!self.currentElementValue) {
        self.currentElementValue = [NSMutableString stringWithString:string];
    } else {
        [self.currentElementValue appendString:string];
    }    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if ([self isElementDictionary:elementName]) {
        self.currentParentElement = [self parentOfElement:elementName];
    } else {
        //trim and save finished current element
        if(self.currentElementValue) {
            
            NSString *trimmedElementValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            self.currentElementValue = nil;
            [self.currentParentElement setObject:trimmedElementValue forKey:elementName];
        }
    }
    [self.currentElementNames removeLastObject];
}

#pragma mark - Helpers

- (BOOL)isElementDictionary:(NSString *)elementName {
    
    id element = [self findElement:elementName];
    BOOL result = [element isKindOfClass:[NSDictionary class]];
    return result;
}

- (NSMutableDictionary *)parentOfElement:(NSString *)elementName {
    
    NSUInteger indexOfElement = [self.currentElementNames indexOfObject:elementName];
    if (indexOfElement > 0 && indexOfElement != NSNotFound) {
        NSString *parentName = self.currentElementNames[indexOfElement - 1];
        NSMutableDictionary *result = [self findElement:parentName];
        return result;
    } else {
        return nil; //elementName is top level
    }
}

- (id)findElement:(NSString *)elementName {
    
    //find root parent
    NSUInteger containerIndex = 0;
    NSString *containerName = self.currentElementNames[containerIndex];
    id result = self.parsedResponse[containerName];
    
    //navigate branch till we have the element
    while (![elementName isEqualToString:containerName]) {
        containerIndex++;
        containerName = self.currentElementNames[containerIndex];
        result = result[containerName];
    }
    return result;
}

@end
