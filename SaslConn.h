//
//  SaslConn.h
//  SaslTest
//
//  Created by Sven Weidauer on 06.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AsyncSocket;

typedef enum {
    SaslConnFailed,
    SaslConnSuccess,
    SaslConnContinue
} SaslConnStatus;

enum SaslConnFlags {
    SaslConnNoPlaintext     = 1 << 0,
    SaslConnNoAnonymous     = 1 << 1,
    SaslConnSuccessData     = 1 << 2,
    SaslConnNeedProxy       = 1 << 3,
};

typedef NSUInteger SaslConnFlags;

@interface SaslConn : NSObject {
@private
    void *conn;
    NSString *mechanism;

    NSString *realm;
    NSString *authName;
    NSString *user;
    NSString *password;
    
    NSMutableArray *authComponents;
}

@property (readonly, retain) NSString *mechanism;

@property (readwrite, copy) NSString *realm;
@property (readwrite, copy) NSString *authName;
@property (readwrite, copy) NSString *user;
@property (readwrite, copy) NSString *password;

- initWithService: (NSString *) service server: (NSString *) serverFQDN 
          localIp: (NSString *) localIp remoteIp: (NSString *) remoteIp
            flags: (SaslConnFlags) flags;

- initWithService: (NSString *) service server: (NSString *) serverFQDN 
           socket: (AsyncSocket *) socket flags: (SaslConnFlags) flags;


- (SaslConnStatus) startWithMechanisms: (NSString *) mechList clientOut: (NSData **) outData;
- (SaslConnStatus) continueWithServerData: (NSData *) serverData clientOut: (NSData **) outData;
- (SaslConnStatus) finishWithServerData: (NSData *) serverData;

- (NSData *) encodeData: (NSData *) inData;
- (NSData *) decodeData: (NSData *) inData;

- (BOOL) needsToEncodeData;

- (NSError *) lastError;

@end
