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


