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


#import "SieveClient.h"
#import "NSData+Base64Encoding.h"
#import "NSScanner+QuotedString.h"

// TODO: Verschiedene Empfangs-Routinen aufspalten und vereinheltichen

@interface SieveClient ()

@property (readwrite, copy) NSString *host;
@property (readwrite, retain) AsyncSocket *socket;
@property (readwrite, retain) SaslConn *sasl;
@property (readwrite, copy) NSString *availableMechanisms;
@property (readwrite, assign) SieveClientStatus status;

- (void) processResponseLine: (NSData *)readData list: (NSMutableArray *) receivedResponses block: (void (^)(NSDictionary *))completionBlock;
- (void) receiveResponse: (void (^)(NSDictionary *))completionBlock;
- (void) send: (NSString *) line completion: (void (^)(NSDictionary *))completionBlock;
- (void) send: (NSString *) line;

@end

@implementation SieveClient

@synthesize availableMechanisms;
@synthesize host, socket;
@synthesize status;
@synthesize sasl;
@synthesize startTLSIfPossible;
@synthesize delegate;

- (void) dealloc;
{
    [self setHost: nil];
    [self setSocket: nil];
    [self setSasl: nil];
    
    [super dealloc];
}

#pragma mark -


- (void) receiveCaps: (NSDictionary *) response;
{
    if ([[response objectForKey: @"responseCode"] isEqualToString: @"OK"]) {
        bool notifyDelegate = YES;
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
                        notifyDelegate = NO;
                        break; // muss nicht weiter bearbeitet werden, nach TLS handshake kommt sowieso neue caps
                    }
                    
                } else if ([item isEqualToString: @"sieve"]) {
                    // TODO: in array splitten und speichern als verfügbare erweiterungen speichern
                    
                } else if ([item isEqualToString: @"notify"]) {
                    // TODO: in array splitten und speichern als verfügbare notify-methoden speichern
                }
            }
        }
        
        if (notifyDelegate) {
            [delegate sieveClientEstablishedConnection: self];
        }
    } else {
        NSLog( @"Capability response is not OK" );
        // TODO: notify delegate
    }
}

- (void) connectToURL: (NSURL *) url;
{
    NSAssert( [[url scheme] isEqualToString: @"sieve"], @"Accepting only sieve URLs" );
    
    unsigned port = 2000;
    
    NSNumber *urlPort = [url port];
    if (nil != urlPort) {
        port = [urlPort unsignedIntValue];
    }
    
    [self connectToHost: [url host] port: port];
}

- (void) connectToHost: (NSString *) newHost port: (unsigned) port;
{
    NSAssert( status == SieveClientDisconnected, @"Cannot connect if already connected" );
    
    [[self mutableArrayValueForKey: @"log"] removeAllObjects];
    [self setHost: newHost]; 
    
    NSLog( @"connecting to %@:%d", host, port );
    [self setSocket: [[[AsyncSocket alloc] initWithDelegate: self] autorelease]];
    [socket connectToHost: host onPort: port error: NULL];
    
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
        NSLog( @"Response to STARTTLS: %@", info );
        if ([[info objectForKey: @"responseCode"] isEqualToString: @"OK"]) {
            NSLog( @"OK, telling socket to start tls negotiation" );
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
        NSLog( @"%@ response: %@", responseString, receivedResponses );
        
        NSString *extraInfo = nil;

        if ([scanner scanString: @"(" intoString: NULL]) {
            [scanner scanUpToString: @")" intoString: &extraInfo];
            [scanner scanString: @")" intoString: NULL];
            NSLog( @"extraInfo: %@", extraInfo );
        }
        
        [self readStringFromScanner: scanner completion: ^(NSString *userInfo) {
            NSLog( @"userInfo: %@", userInfo );
            
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
                NSLog( @"auth successful" );
                [self setStatus: SieveClientAuthenticated];
            }
        }
        
        if (status == SieveClientAuthenticated) {
            NSLog( @"letztendlich auth wirklich erfolgreich!!!" );
            if ([sasl needsToEncodeData]) {
                NSLog( @"data should be encoded" );
                // TODO: sasl encoder installieren... wie auch immer
            } else {
                // das sasl-objekt wird nicht mehr benötigt.
                [self setSasl: nil];
            };
            
            // TODO: notify successful auth here
            // [delegate sieveConnectionAuthentificatedSucessfully: self]
        }
        
    } else if ([scanner scanString: @"NO " intoString: NULL]) {
        [self logLine: receivedString from: @"Server"];
        NSLog( @"auth failed." );
        // TODO: benutzer fragen ob neuer versuch unternommen werden soll
        // [delegate sieveConnection: self failedAuthWithError: bla]
        
    } else if ([scanner scanString: @"BYE " intoString: NULL]) {
        [self logLine: receivedString from: @"Server"];
        NSLog( @"auth failed with BYE" );
        [socket disconnect];
        // [delegate sieveConnection: self gotDisconnectedWithError: bla]
        // TODO: notification dass verbindung abgebrochen wurde
        
    } else {
        NSString *rest = @"";
        if ([scanner scanQuotedString: &rest]) receivedString = rest;
        
        NSData *data = [receivedString base64DecodedData];

        NSData *outData = nil;
        SaslConnStatus rc = [sasl continueWithServerData: data clientOut: &outData];
        
        if (rc == SaslConnFailed) {
            NSLog( @"Failed auth" );
            // Der server weiß nicht, dass etwas nicht stimmt, also auth abbrechen mit "*"
            [self sendString: @"\"*\""];
            [self receiveResponse: nil];
            [self disconnect];
            // TODO: [delegate sieveConnection: self gotDisconnectedWithError: bla]
            
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

- (void) auth;
{
    NSAssert( status == SieveClientConnected, @"Wrong status" );
    [self setStatus: SieveClientAuthenticating];
    
    [self setSasl:[[[SaslConn alloc] initWithService: @"sieve" server: host socket: socket flags: SaslConnSuccessData] autorelease]];
    
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
        NSLog( @"SASL AUTH nicht möglich, problem im Client" );
        [self disconnect];
        // TODO: [delegate disconnectedBecauseSASL]
    }
}

#pragma mark -

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
