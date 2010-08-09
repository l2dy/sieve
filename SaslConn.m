//
//  SaslConn.m
//  SaslTest
//
//  Created by Sven Weidauer on 06.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SaslConn.h"
#import "AsyncSocket.h"

#include <sasl/sasl.h>

@interface SaslConn ()
@property (readwrite, retain) NSString *mechanism;
@property (readwrite, retain) NSMutableArray *authComponents;

- (NSData *) storeAuthComponent: (NSString *) value;

@end

@implementation SaslConn
@synthesize mechanism;
@synthesize realm, user, password, authName;
@synthesize authComponents;

static sasl_callback_t SaslCallbacks[] = { 
    { SASL_CB_GETREALM, NULL, NULL }, 
    { SASL_CB_USER, NULL, NULL }, 
    { SASL_CB_AUTHNAME, NULL, NULL }, 
    { SASL_CB_PASS, NULL, NULL }, 
    { SASL_CB_GETOPT, NULL, NULL }, 
    { SASL_CB_CANON_USER, NULL, NULL }, 
    { SASL_CB_LIST_END, NULL, NULL } 
}; 


+ (void) initialize;
{
    if (self == [SaslConn class]) {
        sasl_client_init( SaslCallbacks );
        atexit( sasl_done );
    }
}

- (NSData *) storeAuthComponent: (NSString *) value;
{
    const char *str = [value UTF8String];
    unsigned length = strlen( str );
    
    NSData *result = [NSData dataWithBytes: str length: length];
    
    if (nil == authComponents) {
        [self setAuthComponents: [NSMutableArray arrayWithObject: result]];
    } else {
        [authComponents addObject: result];
    }
    
    return result;
}

- initWithService: (NSString *) service server: (NSString *) serverFQDN 
           socket: (AsyncSocket *) socket flags: (SaslConnFlags) flags;
{
    NSString *localIp = [NSString stringWithFormat: @"%@;%d", [socket localHost], [socket localPort]];
    NSString *remoteIp = [NSString stringWithFormat: @"%@;%d", [socket connectedHost], [socket connectedPort]];

    return [self initWithService: service server: serverFQDN localIp: localIp remoteIp: remoteIp flags: flags];
}

- initWithService: (NSString *) service server: (NSString *) serverFQDN 
          localIp: (NSString *) localIp remoteIp: (NSString *) remoteIp
            flags: (SaslConnFlags) flags;
{
    if (nil == [super init]) return nil;
    
    unsigned saslFlags = 0;
    if (flags & SaslConnNoAnonymous) saslFlags |= SASL_SEC_NOANONYMOUS;
    if (flags & SaslConnNoPlaintext) saslFlags |= SASL_SEC_NOPLAINTEXT;
    if (flags & SaslConnNeedProxy) saslFlags |= SASL_NEED_PROXY;
    if (flags & SaslConnSuccessData) saslFlags |= SASL_SUCCESS_DATA;
    
    int rc = sasl_client_new([service UTF8String], [serverFQDN UTF8String], [localIp UTF8String], 
                             [remoteIp UTF8String], NULL, saslFlags, (sasl_conn_t **)&conn );
    if (SASL_OK != rc) {
        const char *errstring = sasl_errstring( rc, "de", NULL );
        NSLog( @"sasl error: %d: %s", rc, errstring );
        [self release];
        return nil;
    }
    
    return self;
}

-(void) fillPrompts: (sasl_interact_t *) prompts;
{
    for (int i = 0; prompts[i].id != SASL_CB_LIST_END; i++) {
        NSString *actualValue = nil;
        switch (prompts[i].id) {
            case SASL_CB_AUTHNAME:
                actualValue = authName;
                break;
                
            case SASL_CB_PASS:
                actualValue = password;
                break;
                
            case SASL_CB_GETREALM:
                actualValue = realm;
                break;
                
            case SASL_CB_USER:
                actualValue = user;
                break;
             
            default:
                NSAssert( NO, @"Error: unknown callback code %x", prompts[i].id );
                break;
        }
        
        if (nil != actualValue) {
            NSData *result = [self storeAuthComponent: actualValue];
            prompts[i].result = [result bytes];
            prompts[i].len = [result length];
        } else {
            prompts[i].result = "";
            prompts[i].len = 0;
        }
        
    }    
}

- (SaslConnStatus) startWithMechanisms: (NSString *) mechList clientOut: (NSData **) outData;
{
    sasl_interact_t *prompts = NULL;
    const char *clientOut = NULL;
    unsigned len = 0;
    const char *mech = NULL;
    
    const char **clientOutParam = &clientOut;
    unsigned *lenParam = &len;
    
    if (NULL == outData) {
        lenParam = NULL;
        clientOutParam = NULL;
    }
    
    int rc = 0;
    for (;;) {
        rc = sasl_client_start( conn, [mechList UTF8String], &prompts, clientOutParam, lenParam, &mech );
        
        if (rc != SASL_INTERACT) break;

        [self fillPrompts: prompts];
    }
    
    if (rc != SASL_CONTINUE) {
        [self setAuthComponents: nil];
    }
    
    if (rc != SASL_OK && rc != SASL_CONTINUE) {
        const char *err = sasl_errdetail( conn );
        const char *errstring = sasl_errstring( rc, "de", NULL );
        NSLog( @"sasl error: %d: %s: %s", rc, errstring, err );
        return SaslConnFailed;
    }
    
    if (NULL != outData) {
        if (NULL != clientOut) *outData = [NSData dataWithBytesNoCopy: (void *)clientOut length: len freeWhenDone: NO];
        else *outData = nil;
    }
    
    [self setMechanism: [NSString stringWithUTF8String: mech]];
    
    return (rc == SASL_OK) ? SaslConnSuccess : SaslConnContinue;
}

- (SaslConnStatus) continueWithServerData: (NSData *) serverData clientOut: (NSData **) outData;
{
    const char *bytes = "";
    unsigned length = 0;
    
    if (nil != serverData) {
        bytes = [serverData bytes];
        length = [serverData length];
    }

    sasl_interact_t *prompts = NULL;
    const char *clientOut = NULL;
    unsigned len = 0;
    
    int rc = 0;
    for (;;) {
        rc = sasl_client_step( conn, bytes, length, &prompts, &clientOut, &len );
        
        if (rc != SASL_INTERACT) break;

        [self fillPrompts: prompts];
    }

    if (rc != SASL_CONTINUE) {
        [self setAuthComponents: nil];
    }
    
    if (rc != SASL_OK && rc != SASL_CONTINUE) {
        const char *err = sasl_errdetail( conn );
        const char *errstring = sasl_errstring( rc, "de", NULL );
        NSLog( @"sasl error: %d: %s: %s", rc, errstring, err );

        return SaslConnFailed;
    }
    
    if (NULL != outData) {
        if (NULL != clientOut) *outData = [NSData dataWithBytesNoCopy: (void *)clientOut length: len freeWhenDone: NO];
        else *outData = nil;
    }

    return (rc == SASL_OK) ? SaslConnSuccess : SaslConnContinue;
}

- (SaslConnStatus) finishWithServerData: (NSData *) serverData;
{
    return [self continueWithServerData: serverData clientOut: NULL];
}

- (NSData *) encodeData: (NSData *) inData;
{
    unsigned outLen = 0;
    const char *outData = NULL;
    
    int rc = sasl_encode( conn, [inData bytes], [inData length], &outData, &outLen );
    if (SASL_OK != rc) return nil;
    
    return [NSData dataWithBytesNoCopy: (void *)outData length: outLen freeWhenDone: NO];
}


- (NSData *) decodeData: (NSData *) inData;
{
    unsigned outLen = 0;
    const char *outData = NULL;
    
    int rc = sasl_decode( conn, [inData bytes], [inData length], &outData, &outLen );
    if (SASL_OK != rc) return nil;
    
    return [NSData dataWithBytesNoCopy: (void *)outData length: outLen freeWhenDone: NO];    
}

- (BOOL) needsToEncodeData;
{
    const sasl_ssf_t *ssf = NULL;
    int rc = sasl_getprop( conn, SASL_SSF, (const void **)&ssf );
    if (SASL_OK != rc) return YES;
    
    return *ssf != 0;
}

- (void) dealloc;
{
    if (NULL != conn) {
        sasl_dispose( (sasl_conn_t **)&conn );
    }
    
    [self setUser: nil];
    [self setPassword: nil];
    [self setRealm: nil];
    [self setAuthName: nil];
    [self setMechanism: nil];
    [self setAuthComponents: nil];
    
    [super dealloc];
}

- (NSError *) lastError;
{
    // TODO: Implementieren
    return nil;
}
@end
