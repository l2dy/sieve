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

typedef void (^MockSockReadCompletionBlock_t)( NSData *data );
typedef void (^MockSockWriteCompletionBlock_t)();

@interface MockSocket : NSObject {
    NSData *data;
    NSMutableData *writtenData;
    
    NSUInteger currentLocation;
    unsigned connectedPort;
    unsigned connectCount;
}

- (unsigned) mockConnectCount;

- (void) setMockData: (NSData *) newData;
- (NSData *) mockSentData;
- (void) mockClearSentData;

- (unsigned) connectedPort;

- (BOOL) connectToHost: (NSString *) host onPort: (unsigned) port error: (NSError **) outError;

- (void)readDataToLength:(CFIndex)length withTimeout:(NSTimeInterval)timeout tag:(long)tag block: (MockSockReadCompletionBlock_t) block;
- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag block: (MockSockReadCompletionBlock_t) block;

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag block: (MockSockWriteCompletionBlock_t) block;
@end
