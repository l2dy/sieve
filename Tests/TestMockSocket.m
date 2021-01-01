/* Copyright (c) 1010 Sven Weidauer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
 * to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the 
 * Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
 * THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
 */

#import <XCTest/XCTest.h>

#import "MockSocket.h"

@interface TestMockSocket : XCTestCase {
    MockSocket *sock;
}

@end

@implementation TestMockSocket

- (void) setUp;
{
    sock = [[[MockSocket alloc] init] autorelease];
    NSString *string = @"1234567890abcdefghijklmnop";
    NSData *data = [string dataUsingEncoding: NSASCIIStringEncoding];
    [sock setMockData: data];
}


- (void) tearDown;
{
    sock = nil;
}


- (void) testReadDataToLengthWithBlock;
{
    __block BOOL didCallBlock = NO;
    [sock readDataToLength: 10 withTimeout: -1 tag: 0 block: ^(NSData *data) {
        XCTAssertTrue( [data length] == 10, @"Should have read 10 bytes" );
        NSString *string = [[[NSString alloc] initWithData:  data encoding: NSASCIIStringEncoding] autorelease];
        XCTAssertEqualObjects( string, @"1234567890", @"should have read the string 1234567890" );
        didCallBlock = YES;
    } ];

    XCTAssertTrue( didCallBlock, @"Block should have been called" );


    didCallBlock = NO;
    [sock readDataToLength: 10 withTimeout: -1 tag: 0 block: ^(NSData *data) {
        XCTAssertTrue( [data length] == 10, @"Should have read 10 bytes" );
        NSString *string = [[[NSString alloc] initWithData:  data encoding: NSASCIIStringEncoding] autorelease];
        XCTAssertEqualObjects( string, @"abcdefghij", @"should have read the string abcdefghij" );
        didCallBlock = YES;
    } ];
    
    XCTAssertTrue( didCallBlock, @"Block should have been called" );
    

}


- (void) testReadDataToDataWithBlock;
{
    __block BOOL didCallBlock = NO;
    
    NSData *data = [@"abc" dataUsingEncoding:  NSASCIIStringEncoding];
    [sock readDataToData: data withTimeout: -1 tag: 0 block: ^(NSData *data) {
        XCTAssertTrue( [data length] == 10, @"Should have read 10 bytes" );
        NSString *string = [[[NSString alloc] initWithData:  data encoding: NSASCIIStringEncoding] autorelease];
        XCTAssertEqualObjects( string, @"1234567890", @"should have read the string 1234567890" );
        didCallBlock = YES;
    } ];
    
    XCTAssertTrue( didCallBlock, @"Block should have been called" );

    didCallBlock = NO;
    [sock readDataToLength: 10 withTimeout: -1 tag: 0 block: ^(NSData *data) {
        XCTAssertTrue( [data length] == 10, @"Should have read 10 bytes" );
        NSString *string = [[[NSString alloc] initWithData:  data encoding: NSASCIIStringEncoding] autorelease];
        XCTAssertEqualObjects( string, @"defghijklm", @"should have read the string abcdefghij" );
        didCallBlock = YES;
    } ];
    
    XCTAssertTrue( didCallBlock, @"Block should have been called" );
    
}


- (void) testWriteDataWithBlock;
{
    __block BOOL didCallBlock = NO;
    
    id x;
    NSData *testData = [@"abcde" dataUsingEncoding: NSASCIIStringEncoding];
    [sock writeData: testData withTimeout: -1 tag: 0 block: ^{
        XCTAssertEqualObjects( testData, [sock mockSentData], @"Should have returned the same data that was sent" );
        didCallBlock = YES;
    }];
    
    XCTAssertTrue( didCallBlock, @"Block should have been called" );
    
    [sock mockClearSentData];
    XCTAssertNil( [sock mockSentData], @"Sent data should be nil" );
    
    [sock writeData: testData withTimeout: -1 tag: 0];
    XCTAssertEqualObjects( testData, [sock mockSentData], @"Should have returned the same data that was sent" );
}

- (void) testConnect;
{
    BOOL success = [sock connectToHost: @"localhost" onPort: 42 error: NULL];
    XCTAssertTrue( success, @"Connect should be successful" );
    XCTAssertTrue( 42 == [sock connectedPort], @"connected port should be 42" );
    XCTAssertTrue( 1 == [sock mockConnectCount], @"connect count should be 1" );
}

@end

