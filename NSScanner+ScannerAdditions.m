//
//  NSScanner+ScannerAdditions.m
//  Sieve
//
//  Created by Sven Weidauer on 04.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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

