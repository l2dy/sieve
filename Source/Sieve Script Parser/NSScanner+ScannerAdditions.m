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


#import "NSScanner+ScannerAdditions.h"


@implementation  NSScanner (ScannerAdditions) 
- (unichar) currentCharacter;
{
    NSAssert( ![self isAtEnd], @"at end" );
    return [[self string] characterAtIndex: [self scanLocation]];
}

- (void) skipCharacter;
{
    NSAssert( ![self isAtEnd], @"at end" );
    [self setScanLocation: [self scanLocation] + 1];
}

- (BOOL) scanLineTerminator;
{
    if ([self isAtEnd]) return NO;
    switch ([self currentCharacter]) {
        case '\r': 
            [self skipCharacter];
            if (![self isAtEnd] && [self currentCharacter] == '\n') [self skipCharacter];
            return YES;
            
        case '\n': 
        case L'\x000c':
        case L'\x0085':
        case L'\x2028':
        case L'\x2029':
            [self skipCharacter];
            return YES;
            
        default: 
            return NO;
    }
}

- (BOOL) scanCharacterFromSet: (NSCharacterSet *) set intoChar: (unichar *) outChar;
{
    if ([self isAtEnd]) return NO;
    
    char ch = [self currentCharacter];
    if ([set characterIsMember: ch]) {
        [self skipCharacter];
        if (outChar) *outChar = ch;
        return YES;
    }
    
    return NO;
}

- (BOOL) scanCharacter: (unichar) ch;
{
    if ([self isAtEnd]) return NO;
    
    if ([self currentCharacter] == ch) {
        [self skipCharacter];
        return YES;
    }
    
    return NO;
}

- (BOOL) scanNextCharacterIntoChar: (unichar *) outChar;
{
    if ([self isAtEnd]) return NO;
    
    if (outChar) *outChar = [self currentCharacter];
    [self skipCharacter];
    
    return YES;
}

@end

