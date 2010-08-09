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
