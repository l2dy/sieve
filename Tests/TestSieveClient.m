//
//  TestSieveClient.m
//  Sieve
//
//  Created by Sven Weidauer on 04.09.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import <OCMock/OCMock.h>
#import <objc/objc-class.h>

#import "SieveClient.h"
@interface SieveClient (testInternals)
- (void) setSocket: (AsyncSocket *) newSocket;
- (void) setSasl: (SaslConn *) newSasl;
@end

@interface TestSieveClient : SenTestCase {
    id mockSocket;
    id mockSasl;
    SieveClient *client;
    id mockDelegate;
}

@end

@implementation TestSieveClient


- (void) setUp;
{
    mockSocket = [[OCMockObject niceMockForClass: [AsyncSocket class]] retain];
    mockSasl = [[OCMockObject niceMockForClass:  [SaslConn class]] retain];
    mockDelegate = [[OCMockObject niceMockForProtocol: @protocol(SieveClientDelegate)] retain];
    client = [[SieveClient alloc] init];

    id mockClient = [OCMockObject partialMockForObject: client];
    [[[mockClient stub] andDo: ^(NSInvocation *inv) {
        object_setInstanceVariable( client, "socket", [mockSocket retain] );
    }] setSocket: OCMOCK_ANY];
    
    [[[mockClient stub] andDo: ^(NSInvocation *inv) {
        object_setInstanceVariable( client, "sasl", [mockSasl retain] );
    }] setSasl: OCMOCK_ANY];
    
    [client setDelegate: mockDelegate];
}

- (void) tearDown;
{
    [mockDelegate verify];
    [mockSasl verify];
    [mockSocket verify];
    
    [client release], client = nil;
    [mockDelegate release], mockDelegate = nil;
    [mockSasl release], mockSasl = nil;
    [mockSocket release], mockSocket = nil;
}

- (void) testConnect;
{
    BOOL yes = YES;
    [[[mockSocket expect] andReturnValue: OCMOCK_VALUE(yes)] connectToHost: @"localhost" onPort: 2000 error: NULL ];
    [client connectToHost:  @"localhost" port: 2000];
}

- (void) testConnectURL;
{
    BOOL yes = YES;
    [[[mockSocket expect] andReturnValue: OCMOCK_VALUE(yes)] connectToHost: @"localhost" onPort: 2000 error: NULL ];
    [client connectToURL: [NSURL URLWithString:  @"sieve://localhost"]];
}

- (void) testConnectURLWithPort;
{
    BOOL yes = YES;
    [[[mockSocket expect] andReturnValue: OCMOCK_VALUE(yes)] connectToHost: @"localhost" onPort: 42 error: NULL ];
    [client connectToURL: [NSURL URLWithString:  @"sieve://localhost:42"]];
}



@end
