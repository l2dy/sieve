/* Copyright (c) 2010 Sven Weidauer
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


#import "SieveClient.h"
#import "NSData+Base64Encoding.h"
#import "NSScanner+QuotedString.h"
#import "SieveOperation.h"
#import "SieveClientInternals.h"

// TODO: Verschiedene Empfangs-Routinen aufspalten und vereinheltichen

NSString *const kSieveURLScheme = @"sieve";
NSString * const kSieveErrorDomain = @"SieveErrorDomain";
NSString * const kSieveErrorResponseDictKey = @"SieveErrorResponseDictKey";

static const uint32_t kSieveProtocolType = FOUR_CHAR_CODE( 'SieV' );

@interface SieveClient ()

@property (readwrite, copy) NSString *host;
@property (readwrite, retain) AsyncSocket *socket;
@property (readwrite, retain) SaslConn *sasl;
@property (readwrite, copy) NSString *availableMechanisms;
@property (readwrite, assign) SieveClientStatus status;
@property (nonatomic, readwrite, retain) NSMutableArray *operations;
@property (readwrite, retain) SieveOperation *currentOperation;

- (void) processResponseLine: (NSData *)readData list: (NSMutableArray *) receivedResponses block: (void (^)(NSDictionary *))completionBlock;
- (void) receiveResponse: (void (^)(NSDictionary *))completionBlock;
- (void) authWithUser: (NSString *) userName andPassword: (NSString *) password;

@end

@implementation SieveClient

@synthesize availableMechanisms;
@synthesize host, socket;
@synthesize status;
@synthesize sasl;
@synthesize startTLSIfPossible;
@synthesize delegate;
@synthesize user;
@synthesize operations;
@synthesize currentOperation;

- (NSMutableArray *) operations;
{
    if (nil == operations) {
        operations = [[NSMutableArray alloc] init];
    }
    return operations;
}

- init;
{
    if (nil == [super init]) return nil;
    startTLSIfPossible = YES;
    return self;
}

- (void) dealloc;
{
    [self setHost: nil];

    [socket setDelegate: nil];
    [self setSocket: nil];
    
    [self setSasl: nil];
    
    [super dealloc];
}

#pragma mark -


- (void) receiveCaps: (NSDictionary *) response;
{
    if ([[response objectForKey: @"responseCode"] isEqualToString: @"OK"]) {
        bool readyForAuth = YES;
        for (NSString *line in [response objectForKey: @"response"]) {
            NSScanner *scanner = [NSScanner scannerWithString: line];
            [scanner setCaseSensitive: NO];
            
            NSString *item = nil;
            if ([scanner scanQuotedString: &item]) {
                item = [item lowercaseString];
                
                NSString *rest = @"";
                [scanner scanQuotedString: &rest];
                
                if ([item isEqualToString: @"sasl"]) {
                    [self setAvailableMechanisms: rest];
                    
                } else if ([item isEqualToString: @"starttls"]) {
                    if (startTLSIfPossible && !TLSActive) {
                        [self startTLS]; 
                        readyForAuth = NO;
                        break; // muss nicht weiter bearbeitet werden, nach TLS handshake kommt sowieso neue caps
                    }
                    
                } else if ([item isEqualToString: @"sieve"]) {
                    // TODO: in array splitten und speichern als verfügbare erweiterungen speichern
                    
                } else if ([item isEqualToString: @"notify"]) {
                    // TODO: in array splitten und speichern als verfügbare notify-methoden speichern
                }
            }
        }
        
        if (readyForAuth) {
            [self setStatus: SieveClientConnected];
            if ([delegate respondsToSelector: @selector( sieveClientEstablishedConnection: )]) {
                [delegate sieveClientEstablishedConnection: self];
            }
            [self auth];
        }
    } else {
        // TODO: notify delegate
    }
}

- (void) connectToURL: (NSURL *) url;
{
    NSAssert( [[url scheme] isEqualToString: kSieveURLScheme], @"Accepting only sieve URLs" );
    
    unsigned port = kSieveDefaultPort;
    
    NSNumber *urlPort = [url port];
    if (nil != urlPort) {
        port = [urlPort unsignedIntValue];
    }
    
    [self setUser: [url user]];
    
    [self connectToHost: [url host] port: port];
}

- (void) connectToHost: (NSString *) newHost port: (unsigned) port;
{
    NSAssert( status == SieveClientDisconnected, @"Cannot connect if already connected" );
    
    [[self mutableArrayValueForKey: @"log"] removeAllObjects];
    [self setHost: newHost]; 
    
    [self setSocket: [[[AsyncSocket alloc] initWithDelegate: self] autorelease]];
    NSError *error = nil;
    [socket connectToHost: host onPort: port error: &error];

    NSLog(@"Error %@", error);
    [self receiveResponse: ^(NSDictionary *response) {
        [self receiveCaps: response];
    }];
}

- (void) disconnect;
{
    NSAssert( status != SieveClientDisconnected, @"Already disconnected" );
    
    [self send: @"LOGOUT"];
    [socket disconnect];
}

- (void) startTLS;
{
    [self send: @"STARTTLS" completion: ^(NSDictionary *info) {
        if ([[info objectForKey: @"responseCode"] isEqualToString: @"OK"]) {
            [socket startTLS: nil];
            TLSActive = true;
            [self receiveResponse: ^(NSDictionary *response) {
                [self receiveCaps: response];
            }];
        }
    }];
}

- (void) logLine: (NSString *) line from: (NSString *) source;
{
    [[self mutableArrayValueForKey: @"log"] addObject: [NSDictionary dictionaryWithObjectsAndKeys: line, @"line", source, @"who", nil]];
}

- (void) sendString: (NSString *) line;
{
    NSData *lineData = [[line stringByAppendingString: @"\r\n"] dataUsingEncoding: NSUTF8StringEncoding];
    [socket writeData: lineData withTimeout: -1 tag: 0];
}

- (void) sendData: (NSData *) data
{
    [socket writeData: data withTimeout: -1 tag: 0];
}

- (void) send: (NSString *) line completion: (void (^)(NSDictionary *))completionBlock;
{
    [self logLine: line from: @"Client"];
    [self sendString: line];
    [self receiveResponse: completionBlock];
}

- (void) send: (NSString *) line;
{
    [self send: line completion: nil];
}

- (void) receiveNextLine: (NSMutableArray *) responses block: (void (^)(NSDictionary *))completionBlock;
{
    [socket readDataToData: [AsyncSocket CRLFData] withTimeout: -1 tag: 0 block: ^(NSData * received) {
        [self processResponseLine: received list: responses block: completionBlock];
    }];
}


- (void) readStringFromScanner: (NSScanner *) scanner completion: (void (^)(NSString *)) block;
{
    if ([scanner scanString: @"{" intoString: NULL]) {
        int stringLength = 0;
        [scanner scanInt: &stringLength];
        
        [socket readDataToLength: stringLength + 2 withTimeout: -1 tag: 0 block: ^(NSData *readData){
            NSString *str = [[[NSString alloc] initWithData: readData encoding: NSUTF8StringEncoding] autorelease];
            block( str );
        }];
    } else {
        NSString *result = [[scanner string] substringFromIndex: [scanner scanLocation]];
        block( result );
    }
}

- (void) receiveString: (void (^)(NSString *)) completionBlock;
{
    [socket readDataToData: [AsyncSocket CRLFData] withTimeout: -1 tag: 0 block: ^(NSData * received) {
        NSString *receivedLine = [[[NSString alloc] initWithData: received encoding: NSUTF8StringEncoding] autorelease];
        NSScanner *scanner = [NSScanner scannerWithString: receivedLine];
        [scanner setCaseSensitive: NO];
        [self readStringFromScanner: scanner completion: completionBlock];
    }];
}

- (void) processResponseLine: (NSData *)readData list: (NSMutableArray *) receivedResponses block: (void (^)(NSDictionary *))completionBlock;
{
    NSString *receivedLine = [[[NSString alloc] initWithData: readData encoding: NSUTF8StringEncoding] autorelease];

    NSScanner *scanner = [NSScanner scannerWithString: receivedLine];
    [scanner setCaseSensitive: NO];

    NSString *responseString = nil;
    if ([scanner scanString: @"OK" intoString: &responseString] || [scanner scanString: @"NO" intoString: &responseString] || [scanner scanString: @"BYE" intoString: &responseString]) {
        [self logLine: receivedLine from: @"Server"];
        
        NSString *extraInfo = nil;

        if ([scanner scanString: @"(" intoString: NULL]) {
            [scanner scanUpToString: @")" intoString: &extraInfo];
            [scanner scanString: @")" intoString: NULL];
        }
        
        [self readStringFromScanner: scanner completion: ^(NSString *userInfo) {
            if (completionBlock != nil) {
                NSMutableDictionary *completeResponse = [NSMutableDictionary dictionary];
                [completeResponse setObject:responseString forKey:@"responseCode"];
                if (extraInfo) [completeResponse setObject:extraInfo forKey:@"extraInfo"];
                if (userInfo) [completeResponse setObject: userInfo forKey: @"userInfo"];
                if ([receivedResponses count] > 0) {
                    [completeResponse setObject: receivedResponses forKey: @"response"];
                }
                completionBlock( completeResponse );
            }
            
        }];
        
    } else {
        [self readStringFromScanner: scanner completion: ^(NSString * line) {
            [receivedResponses addObject: line];
            [self receiveNextLine: receivedResponses block: (void (^)(NSDictionary *))completionBlock];
        }];
    }
}

- (void) receiveResponse: (void (^)(NSDictionary *))completionBlock;
{
    NSMutableArray *receivedResponses = [NSMutableArray array];

    [self receiveNextLine: receivedResponses block: completionBlock];
}

- (void) authStep: (NSString *) receivedString;
{
    NSScanner *scanner = [NSScanner scannerWithString: receivedString];
    
    if ([scanner scanString: @"OK " intoString: NULL]) {
        [self logLine: receivedString from: @"Server"];
        NSData *lastData = nil;
        
        if ([scanner scanString: @"(SASL" intoString: NULL]) {
            NSString *rest = @"";
            if ([scanner scanQuotedString: &rest]) lastData = [rest base64DecodedData];
        }
        
        if (lastData || (status != SieveClientAuthenticated)) {
            SaslConnStatus rc = [sasl finishWithServerData: lastData];
            if (rc == SaslConnSuccess) {
                [self setStatus: SieveClientAuthenticated];
            }
        }
        
        if (status == SieveClientAuthenticated) {
            NSAssert( ![sasl needsToEncodeData], @"Sieve security layers are not supported." );
            [self setSasl: nil];
            
            if ([delegate respondsToSelector: @selector( sieveClientSucceededAuth: )]) {
                [delegate sieveClientSucceededAuth: self];
            }
            [self startNextOperation];
        }
        
    } else if ([scanner scanString: @"NO " intoString: NULL]) {
        [self logLine: receivedString from: @"Server"];
        [self setStatus: SieveClientConnected];
        [delegate sieveClient: self needsCredentials: nil];
        
    } else if ([scanner scanString: @"BYE " intoString: NULL]) {
        [self logLine: receivedString from: @"Server"];
        [socket disconnect];
        // TODO: Notify delegate that connection was dropped
        
    } else {
        NSString *rest = @"";
        if ([scanner scanQuotedString: &rest]) receivedString = rest;
        
        NSData *data = [receivedString base64DecodedData];

        NSData *outData = nil;
        SaslConnStatus rc = [sasl continueWithServerData: data clientOut: &outData];
        
        if (rc == SaslConnFailed) {
            // Abort the auth by sending "*"
            [self sendString: @"\"*\""];
            [self receiveResponse: nil];
            [self disconnect];
            // TODO: Notify delegate that connection was dropped
            
        } else {
            if (rc == SaslConnSuccess) [self setStatus: SieveClientAuthenticated];
            
            NSString *authCommand = @"\"\"";
            if (nil != outData) authCommand = [NSString stringWithFormat: @"\"%@\"", [outData base64EncodedString]];

            [self sendString: authCommand];
            [self receiveString: ^( NSString *receivedString ) {
                [self authStep: receivedString];
            }];
        }
    }
    
}

- (void) continueAuthWithCredentials: (NSURLCredential *) creds;
{
    if ([creds persistence] == NSURLCredentialPersistencePermanent) {
        NSData *serverData = [host dataUsingEncoding: NSUTF8StringEncoding];
        NSData *userData = [[creds user] dataUsingEncoding: NSUTF8StringEncoding];
        NSData *passwordData = [[creds password] dataUsingEncoding: NSUTF8StringEncoding];
        SecKeychainAddInternetPassword( NULL, [serverData length], [serverData bytes], 0, NULL, 
                                       [userData length], [userData bytes], 0, NULL, [socket connectedPort], 
                                       kSieveProtocolType, kSecAuthenticationTypeDefault, 
                                       [passwordData length], [passwordData bytes], NULL );
    }
    [self authWithUser: [creds user] andPassword: [creds password]];
}

- (void) cancelAuth;
{
    // TODO: Disconnect socket
}

- (void) authWithUser: (NSString *) userName andPassword: (NSString *) password;
{
    NSAssert( status == SieveClientConnected, @"Wrong status" );
    [self setStatus: SieveClientAuthenticating];
    
    [self setSasl:[[[SaslConn alloc] initWithService: kSieveURLScheme server: host socket: socket flags: SaslConnSuccessData] autorelease]];
    
    [self setUser: userName];
    [sasl setAuthName: userName];
    [sasl setPassword: password];

    NSData *outData = nil;
    SaslConnStatus rc = [sasl startWithMechanisms: availableMechanisms clientOut: &outData];
    if (rc != SaslConnFailed) {
        if (SaslConnSuccess == rc) [self setStatus: SieveClientAuthenticated];
        
        NSString *authCommand = [NSString stringWithFormat: @"AUTHENTICATE \"%@\"", [sasl mechanism]];
        [self logLine: authCommand from: @"Client"];
        
        if (outData) {
            NSString *encodedData = [outData base64EncodedString];
            authCommand = [authCommand stringByAppendingFormat: @" \"%@\"", encodedData];
        }
        
        [self sendString: authCommand];
        [self receiveString: ^( NSString *receivedString ) {
            [self authStep: receivedString];
        }];
    } else {
        [self disconnect];
        // TODO: Notify delegate that connection was dropped
    }
}

- (void) auth;
{
    NSString *userName = [self user];
    NSString *password = nil;

    if (!triedKeychain) {
        NSData *serverName = [host dataUsingEncoding: NSUTF8StringEncoding];
        UInt32 passwordLength = 0;
        void *passwordData = NULL;
        SecKeychainItemRef item = NULL;
        
        const char *userNameString = NULL;
        unsigned userNameLength = 0;
        
        if (nil != userName) {
            NSData *userNameData = [userName dataUsingEncoding: NSUTF8StringEncoding];
            userNameString = [userNameData bytes];
            userNameLength = [userNameData length];
        }
        
        OSStatus result = SecKeychainFindInternetPassword( NULL, [serverName length], [serverName bytes], 0, NULL,
                                        userNameLength, userNameString, 0, NULL, [socket connectedPort], 
                                        kSieveProtocolType, kSecAuthenticationTypeDefault, 
                                        &passwordLength, &passwordData, &item );
        
        if (errSecSuccess == result) {
            NSData *data = [NSData dataWithBytesNoCopy: passwordData length: passwordLength freeWhenDone: NO];
            password = [[[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding] autorelease];
            
            if (nil == userName) {
                SecKeychainAttribute nameAttribute = {
                    kSecAccountItemAttr, 0, NULL
                };
                SecKeychainAttributeList attrList = {
                    1, &nameAttribute
                };
                result = SecKeychainItemCopyContent( item, NULL, &attrList, NULL, NULL );
                if (result == errSecSuccess) {
                    data = [NSData dataWithBytesNoCopy: nameAttribute.data length: nameAttribute.length freeWhenDone:NO];
                    userName = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
                    SecKeychainItemFreeContent( &attrList, NULL );
                } 
            }
            
            SecKeychainItemFreeContent( NULL, passwordData );
        }
        
        triedKeychain = YES;
    }
    
    if (nil != password && nil != userName) {
        [self authWithUser: userName andPassword: password ];
    } else {
        NSURLCredential *partialCred = [NSURLCredential credentialWithUser: userName password: password persistence: NSURLCredentialPersistenceNone];
        [delegate sieveClient: self needsCredentials: partialCred];
    }
}

- (void) startNextOperation;
{
    if ([operations count] > 0) {
        [self setCurrentOperation: [operations objectAtIndex: 0]];
        [operations removeObjectAtIndex: 0];
        [currentOperation start];
    } else {
        [self setCurrentOperation: nil];
    }
}

- (void) addOperation: (SieveOperation *) operation;
{
    [[self operations] addObject: operation];
    if (nil == currentOperation && status == SieveClientAuthenticated) [self startNextOperation];
}

- (void) putScript: (NSString *) script withName: (NSString *) name delegate: (id) newDelegate userInfo: (void *) userInfo;
{
    [self addOperation: [[[SievePutScriptOperation alloc] initWithScript: script name:name forClient:self delegate:newDelegate userInfo: userInfo] autorelease]];
}

- (void) putScript: (NSString *) script withName: (NSString *) name;
{
    [self putScript: script withName: name delegate: delegate userInfo: NULL];
}

- (void) setActiveScript: (NSString *) scriptName delegate: (id) newDelegate userInfo: (void *) userInfo;
{
    [self addOperation: [[[SieveSetActiveOperation alloc] initWithScript: scriptName forClient: self delegate:newDelegate userInfo: userInfo] autorelease]];
}

- (void) setActiveScript: (NSString *) scriptName;
{
    [self setActiveScript: scriptName delegate: delegate userInfo: NULL];
}

- (void) renameScript: (NSString *) oldName to: (NSString *) newName delegate: (id) newDelegate userInfo: (void *) userInfo;
{
    [self addOperation: [[[SieveRenameScriptOperation alloc] initWithOldName: oldName newName: newName forClient: self delegate:newDelegate userInfo: userInfo] autorelease]];
}

- (void) renameScript: (NSString *) oldName to: (NSString *) newName;
{
    [self renameScript: oldName to: newName delegate: delegate userInfo: NULL];
}

- (void) deleteScript: (NSString *) scriptName delegate: (id) newDelegate userInfo: (void *) userInfo;
{
    [self addOperation: [[[SieveDeleteScriptOperation alloc] initWithScript: scriptName forClient: self delegate:newDelegate userInfo: userInfo] autorelease]];
}

- (void) deleteScript: (NSString *) scriptName;
{
    [self deleteScript: scriptName delegate: delegate userInfo: NULL];
}

- (void) listScriptsWithDelegate: (id) newDelegate userInfo: (void *) userInfo;
{
    [self addOperation: [[[SieveListScriptsOperation alloc] initForClient: self delegate: newDelegate userInfo: userInfo] autorelease]];
}

- (void) listScripts;
{
    [self listScriptsWithDelegate: delegate userInfo: NULL];
}

- (void) getScript: (NSString *) scriptName delegate: (id) newDelegate userInfo: (void *) userInfo;
{
    [self addOperation: [[[SieveGetScriptOperation alloc] initWithScript: scriptName forClient:self delegate:newDelegate userInfo: userInfo] autorelease]];
}

- (void) getScript: (NSString *) scriptName;
{
    [self getScript: scriptName delegate: delegate userInfo: NULL];
}

#pragma mark -
#pragma mark Logging

- (NSArray *)log {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    return [[log retain] autorelease];
}

- (unsigned)countOfLog {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    return [log count];
}

- (id)objectInLogAtIndex:(unsigned)theIndex {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    return [log objectAtIndex:theIndex];
}

- (void)getLog:(id *)objsPtr range:(NSRange)range {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    [log getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inLogAtIndex:(unsigned)theIndex {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    [log insertObject:obj atIndex:theIndex];
}

- (void)removeObjectFromLogAtIndex:(unsigned)theIndex {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    [log removeObjectAtIndex:theIndex];
}

- (void)replaceObjectInLogAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!log) {
        log = [[NSMutableArray alloc] init];
    }
    [log replaceObjectAtIndex:theIndex withObject:obj];
}

@end
