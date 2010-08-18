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
@class SieveOperation;

@protocol SieveClientDelegate < NSObject > 

- (void) sieveClient: (SieveClient *) client needsCredentials: (NSURLCredential *) defaultCreds;
- (void) sieveClientSucceededAuth: (SieveClient *) client;

@optional
- (void) sieveClientEstablishedConnection: (SieveClient *) client;
- (void) sieveClient: (SieveClient *) client retrievedScriptList: (NSArray *) scripts active: (NSString *)activeScript;
- (void) sieveClient: (SieveClient *) client retrievedScript: (NSString *) script withName: (NSString *) scriptName;
- (void) sieveClient: (SieveClient *) client storedScriptWithName: (NSString *) name;

@end

@interface SieveClient : NSObject
{
    NSString *host;
    NSString *user;
    
    AsyncSocket *socket;
    SaslConn *sasl;
    
    NSMutableArray *log;
    
    BOOL startTLSIfPossible;
    BOOL TLSActive;
    NSString *availableMechanisms;
    
    SieveClientStatus status;
    
    __weak id <SieveClientDelegate> delegate;
    
    NSMutableArray *operations;
    SieveOperation *currentOperation;
    
    BOOL triedKeychain;
}

@property (readwrite, assign) id <SieveClientDelegate> delegate;

@property (readonly, copy) NSString *host;
@property (readwrite, copy) NSString *user;
@property (readonly, assign) BOOL startTLSIfPossible;

@property (readonly, assign) SieveClientStatus status;

@property (readonly, copy) NSString *availableMechanisms;


- (void) continueAuthWithCredentials: (NSURLCredential *) creds;
- (void) cancelAuth;

- (void) listScripts;
- (void) getScript: (NSString *) scriptName;
- (void) putScript: (NSString *) script withName: (NSString *) name;
- (void) setActiveScript: (NSString *) scriptName;
- (void) renameScript: (NSString *) oldName to: (NSString *) newName;
- (void) deleteScript: (NSString *) scriptName;

- (void) connectToURL: (NSURL *) url;
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
