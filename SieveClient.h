//
//  MyDocument.h
//  SaslTest
//
//  Created by Sven Weidauer on 06.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "AsyncSocket.h"
#import "SaslConn.h"

@interface SieveClient : NSObject
{
    NSString *host;
    int port;
    AsyncSocket *socket;
    SaslConn *sasl;
    
    NSMutableArray *exchange;
    
    bool startedTls;
    NSString *availableMechanisms;
    
    bool authSuccess;
    
    BOOL startTlsIfPossible;
}

@property (readwrite, copy) NSString *host;
@property (readwrite, copy) NSString *lineToSend;
@property (readwrite, assign) int port;

@property (readwrite, copy) NSString *availableMechanisms;

@property (readwrite, retain) AsyncSocket *socket;


- (void) connect;
- (void) disconnect;

- (void) startTLS;

- (void) auth;


- (NSArray *)exchange;
- (unsigned)countOfExchange;
- (id)objectInExchangeAtIndex:(unsigned)theIndex;
- (void)getExchange:(id *)objsPtr range:(NSRange)range;
- (void)insertObject:(id)obj inExchangeAtIndex:(unsigned)theIndex;
- (void)removeObjectFromExchangeAtIndex:(unsigned)theIndex;
- (void)replaceObjectInExchangeAtIndex:(unsigned)theIndex withObject:(id)obj;

@end
