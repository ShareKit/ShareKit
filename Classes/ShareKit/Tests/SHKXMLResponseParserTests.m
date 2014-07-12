//
//  SHKXMLResponseParserTests.m
//  ShareKit
//
//  Created by Vilem Kurz on 29/11/2013.
//
//

#import <XCTest/XCTest.h>

#import "SHKXMLResponseParser.h"
#import "NSMutableDictionary+NSNullsToEmptyStrings.h"

@interface SHKXMLResponseParserTests : XCTestCase

@end

@implementation SHKXMLResponseParserTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testXMLElements {

    NSData *testXMLData = [self loadTestXML:@"testXMLResponse"];
    NSDictionary *parsedDict = [SHKXMLResponseParser dictionaryFromData:testXMLData];
    NSDictionary *properResultDict = [self properResultDictElements];
    XCTAssert([parsedDict isEqualToDictionary:properResultDict], @"Badly parsed elements xml!");
}

- (void)testXMLAttributes {

    NSData *testXMLData = [self loadTestXML:@"testXMLAttributes"];
    NSDictionary *parsedDict = [SHKXMLResponseParser dictionaryFromData:testXMLData];
    NSDictionary *properResultDict = [self properResultDictAttributes];
    XCTAssert([parsedDict isEqualToDictionary:properResultDict], @"Badly parsed attributes xml!");
}

- (void)testXMLAttributes2 {
    
    NSData *testXMLData = [self loadTestXML:@"testXMLAttributes2"];
    NSDictionary *parsedDict = [SHKXMLResponseParser dictionaryFromData:testXMLData];
    NSDictionary *properResultDict = [self properResultDictAttributes2];
    XCTAssert([parsedDict isEqualToDictionary:properResultDict], @"Badly parsed attributes xml!");
}

- (void)testXMLAttributes3 {
    
    NSData *testXMLData = [self loadTestXML:@"testXMLAttributes3"];
    NSDictionary *parsedDict = [SHKXMLResponseParser dictionaryFromData:testXMLData];
    NSDictionary *properResultDict = [self properResultDictAttributes3];
    XCTAssert([parsedDict isEqualToDictionary:properResultDict], @"Badly parsed attributes xml!");
}


- (void)testValueForElement {
    
    NSData *testXMLData = [self loadTestXML:@"testXMLResponse"];
    NSString *value = [SHKXMLResponseParser getValueForElement:@"empty" fromXMLData:testXMLData];
    XCTAssert([value isEqualToString:@""], "Bad element value");
}

- (NSData *)loadTestXML:(NSString *)name {
    
    NSBundle *unitTestBundle = [NSBundle bundleForClass:[self class]];
    NSString *pathForFile = [unitTestBundle pathForResource:name ofType:@"xml"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:pathForFile];
    return data;
}

- (NSDictionary *)properResultDictElements {
    
    NSDictionary *result = @{@"person":@{@"first-name":@"Vilem",
                                         @"last-name":@"Kurz",
                                         @"headline":@"iOS developer",
                                         @"site-standard-profile-request":@{@"url":@"http://www.linkedin.com/profile/view?id=159323245&authType=name&authToken=hj_Q&trk=api*a157605*s165834*",
                                                                            @"empty":@""}}};
    return result;
}

- (NSDictionary *)properResultDictAttributes {
    
    NSDictionary *result = @{@"result":@{@"code": @"url (or urls) required"}};
    return result;
}

- (NSDictionary *)properResultDictAttributes2 {
    
    NSDictionary *result = @{@"rsp": @{@"stat": @"ok",
                                       @"mediaid": @"",
                                       @"mediaurl": @"http://yfrog.com/"}};
    return result;
}

- (NSDictionary *)properResultDictAttributes3 {
    
    NSDictionary *result = @{@"rsp": @{@"stat": @"ok",
                                       @"user": @{@"id": @"75231457@N02",
                                                  @"username": @"Vito132"}}};
    return result;
}

@end
