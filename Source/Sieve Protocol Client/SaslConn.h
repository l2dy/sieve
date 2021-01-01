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


#import <Cocoa/Cocoa.h>

@class AsyncSocket;

typedef enum {
    SaslConnFailed,     //!< Negotiating the authentication failed
    SaslConnSuccess,    //!< SASL mechanism was successful. 
    SaslConnContinue    //!< More steps are neccessary for authentication
} SaslConnStatus;

enum SaslConnFlags {
    SaslConnNoPlaintext     = 1 << 0,       //!< Don't use plain-text mechanisms
    SaslConnNoAnonymous     = 1 << 1,       //!< Don't use the anonymous mechanism
    SaslConnSuccessData     = 1 << 2,       //!< Protocol can transport more data with success message
    SaslConnNeedProxy       = 1 << 3,       //!< Need a mechanism that supports proxy authentication
};

typedef NSUInteger SaslConnFlags;

extern NSString * const kSASLErrorDomain;

@interface SaslConn : NSObject {
@private
    void *conn;
    NSString *mechanism;

    NSString *realm;
    NSString *authName;
    NSString *user;
    NSString *password;
    
    NSMutableArray *authComponents;
    
    int lastError;
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

/** Returns \a YES if a security layer is negotiated.
 */
- (BOOL) needsToEncodeData;

- (NSError *) lastError;

@end
