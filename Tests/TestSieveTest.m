//
//  TestSieveTest.m
//  Sieve
//
//  Created by Sven Weidauer on 03.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "SieveTest.h"

@interface TestSieveTest : XCTestCase
@end


@implementation TestSieveTest

- (void) checkTest: (SieveTest *) test name: (NSString *) name;
{
    XCTAssertEqualObjects( name, [test name], @"Name should be equal to test" );
    XCTAssertFalse( [test inverted], @"Test should not be inverted" );
    
    SieveTest *inverted = [test invertedTest];
    XCTAssertEqualObjects( name, [inverted name], @"Name should not be changed" );
    XCTAssertTrue( [inverted inverted], @"Inverted test should be inverted" );
}

- (void) testSieveTest;
{
    SieveTest *test = [[[SieveTest alloc] initWithName:  @"test" parameters: nil] autorelease];
    [self checkTest: test name: @"test"];
}

- (void) testAllOfTest;
{
    SieveTest *test = [[[SieveAllOfTest alloc] initWithChildren: nil] autorelease];
    [self checkTest: test name: @"allof"];
}

- (void) testAnyOfTest;
{
    SieveTest *test = [[[SieveAnyOfTest alloc] initWithChildren: nil] autorelease];
    [self checkTest: test name: @"anyof"];
}

- (void) testInvalidInitializers;
{
    XCTAssertThrows( [[SieveAnyOfTest alloc] initWithName:  @"test" parameters: nil], @"Should not be able to create AnyOfTest with name" );
    XCTAssertThrows( [[SieveAllOfTest alloc] initWithName:  @"test" parameters: nil], @"Should not be able to create AnyOfTest with name" );
}

@end
