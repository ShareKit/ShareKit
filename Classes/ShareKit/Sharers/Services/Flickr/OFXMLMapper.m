//
// OFXMLMapper.m
//
// Copyright (c) 2009 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "OFXMLMapper.h"

NSString *const OFXMLMapperExceptionName = @"OFXMLMapperException";
NSString *const OFXMLTextContentKey = @"_text";

@implementation OFXMLMapper
- (void)dealloc
{
    [resultantDictionary release];
	[elementStack release];
	[currentElementName release];
    [super dealloc];
}

- (id)init
{
    if ((self = [super init])) {
        resultantDictionary = [[NSMutableDictionary alloc] init];
		elementStack = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)runWithData:(NSData *)inData
{
	currentDictionary = resultantDictionary;
	
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:inData];
	[parser setDelegate:self];
	[parser parse];
	[parser release];
}

- (NSDictionary *)resultantDictionary
{
	return [[resultantDictionary retain] autorelease];
}

+ (NSDictionary *)dictionaryMappedFromXMLData:(NSData *)inData
{
	OFXMLMapper *mapper = [[OFXMLMapper alloc] init];
	[mapper runWithData:inData];
	NSDictionary *result = [mapper resultantDictionary];
	[mapper release];
	return result;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	NSMutableDictionary *mutableAttrDict = attributeDict ? [NSMutableDictionary dictionaryWithDictionary:attributeDict] : [NSMutableDictionary dictionary];

	// see if it's duplicated
	id element = [currentDictionary objectForKey:elementName];
	if (element) {
		if (![element isKindOfClass:[NSMutableArray class]]) {
			if ([element isKindOfClass:[NSMutableDictionary class]]) {
				[element retain];
				[currentDictionary removeObjectForKey:elementName];
				
				NSMutableArray *newArray = [NSMutableArray arrayWithObject:element];
				[currentDictionary setObject:newArray forKey:elementName];
				[element release];
				
				element = newArray;
			}
			else {
				@throw [NSException exceptionWithName:OFXMLMapperExceptionName reason:@"Faulty XML structure" userInfo:nil];
			}
		}
		
		[element addObject:mutableAttrDict];
	}
	else {
		// plural tag rule: if the parent's tag is plural and the incoming is singular, we'll make it into an array (we only handles the -s case)
		
		if ([currentElementName length] > [elementName length] && [currentElementName hasPrefix:elementName] && [currentElementName hasSuffix:@"s"]) {
			[currentDictionary setObject:[NSMutableArray arrayWithObject:mutableAttrDict] forKey:elementName];
		}
		else {
			[currentDictionary setObject:mutableAttrDict forKey:elementName];
		}
	}
	
	[elementStack insertObject:currentDictionary atIndex:0];
	currentDictionary = mutableAttrDict;
	
	NSString *tmp = currentElementName;
	currentElementName = [elementName retain];
	[tmp release];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if (![elementStack count]) {
		@throw [NSException exceptionWithName:OFXMLMapperExceptionName reason:@"Unbalanced XML element tag closing" userInfo:nil];
	}
	
	currentDictionary = [elementStack objectAtIndex:0];
	[elementStack removeObjectAtIndex:0];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	NSString *existingContent = [currentDictionary objectForKey:OFXMLTextContentKey];
	if (existingContent) {
		NSString *newContent = [existingContent stringByAppendingString:string];
		[currentDictionary setObject:newContent forKey:OFXMLTextContentKey];		
	}
	else {
		[currentDictionary setObject:string forKey:OFXMLTextContentKey];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	[resultantDictionary release];
	resultantDictionary = nil;
}
@end

@implementation NSDictionary (OFXMLMapperExtension)
- (NSString *)textContent
{
    return [self objectForKey:OFXMLTextContentKey];
}
@end
