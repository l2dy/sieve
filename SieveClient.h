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

typedef enum {
    SieveClientDisconnected,
    SieveClientConnected,
    SieveClientAuthenticating,
    SieveClientAuthenticated
} SieveClientStatus;

@class SieveClient;

@protocol SieveClientDelegate < NSObject > 

- (void) sieveClientEstablishedConnection: (SieveClient *) client;

@end

@interface SieveClient : NSObject
{
    NSString *host;
    
    AsyncSocket *socket;
    SaslConn *sasl;
    
    NSMutableArray *log;
    
    BOOL startTLSIfPossible;
    BOOL TLSActive;
    NSString *availableMechanisms;
    
    SieveClientStatus status;
    
    __weak id <SieveClientDelegate> delegate;
}

@property (readwrite, assign) id <SieveClientDelegate> delegate;

@property (readonly, copy) NSString *host;
@property (readonly, assign) BOOL startTLSIfPossible;

@property (readonly, assign) SieveClientStatus status;

@property (readonly, copy) NSString *availableMechanisms;


- (void) connectToHost: (NSString *) serverHost port: (unsigned) port;
- (void) disconnect;

- (void) startTLS;

- (void) auth;


- (NSArray *)log;
- (unsigned)countOfLog;
- (id)objectInLogAtIndex:(unsigned)theIndex;
- (void)getLog:(id *)objsPtr range:(NSRange)range;
- (void)insertObject:(id)obj inLogAtIndex:(unsigned)theIndex;
- (void)removeObjectFromLogAtIndex:(unsigned)theIndex;
- (void)replaceObjectInLogAtIndex:(unsigned)theIndex withObject:(id)obj;

@end
