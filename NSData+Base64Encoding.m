//
//  NSData+Base64Encoding.m
//  SaslTest
//
//  Created by Sven Weidauer on 08.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSData+Base64Encoding.h"

#import <sasl/saslutil.h>

@implementation NSData (Base64Encoding)

- (NSString *) base64EncodedString;
{
    NSUInteger length = [self length];
    
    char buffer[2 * length];
    unsigned outLen = 0;
    sasl_encode64( [self bytes], length, buffer, 2 * length, &outLen );
    
    return [[[NSString alloc] initWithData:[NSData dataWithBytes: buffer length: outLen] encoding:NSASCIIStringEncoding] autorelease];
}

@end

@implementation NSString (Base64Decoding)

- (NSData *) base64DecodedData;
{
    const char *cString = [self cStringUsingEncoding: NSASCIIStringEncoding];
    unsigned length = strlen( cString );
    
    char buffer[length];
    
    unsigned outLen = 0;
    sasl_decode64( cString, length, buffer, length, &outLen );
    
    return [NSData dataWithBytes: buffer length: outLen];
}

@end


