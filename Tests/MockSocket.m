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

#import "MockSocket.h"


@implementation MockSocket

- (void) setMockData: (NSData *) newData;
{
    if (newData != data) {
        [data release];
        data = [newData copy];
    }
    currentLocation = 0;
}

- (void)readDataToLength:(CFIndex)length withTimeout:(NSTimeInterval)timeout tag:(long)tag block: (MockSockReadCompletionBlock_t) block;
{
    NSRange range = NSMakeRange( currentLocation, length );
    NSData *subData = [data subdataWithRange: range];
    currentLocation += length;
    
    block( subData );
}

- (void)readDataToData:(NSData *)sd withTimeout:(NSTimeInterval)timeout tag:(long)tag block: (MockSockReadCompletionBlock_t) block;
{
    NSRange range = [data rangeOfData: sd options: 0 range: NSMakeRange( currentLocation, [data length] - currentLocation )];
    if (range.location != NSNotFound) {
        NSRange subdataRange = NSMakeRange( currentLocation, range.location - currentLocation );
        NSData *subData = [data subdataWithRange: subdataRange];
        currentLocation = range.location + [sd length];
        block( subData );
    }
}

- (NSData *) mockSentData;
{
    return writtenData;
}

- (void) mockClearSentData;
{
    [writtenData release]; writtenData = nil;
}

- (void)writeData:(NSData *)dataToSend withTimeout:(NSTimeInterval)timeout tag:(long)tag;
{
    if (nil == writtenData) {
        writtenData = [[NSMutableData alloc] init];
    }
    
    [writtenData appendData: dataToSend];
}

- (void)writeData:(NSData *)dataToSend withTimeout:(NSTimeInterval)timeout tag:(long)tag block: (MockSockWriteCompletionBlock_t) block;
{
    [self writeData: dataToSend withTimeout: timeout tag: tag];
    block();
}

- (unsigned) connectedPort;
{
    return connectedPort;
}

- (BOOL) connectToHost: (NSString *) host onPort: (unsigned) port error: (NSError **) outError;
{
    ++connectCount;
    connectedPort = port;
    return YES;
}

- (unsigned) mockConnectCount;
{
    return connectCount;
}

- (void) disconnect;
{
    
}

- (void) startTLS: (id) x;
{
    
}

@end
