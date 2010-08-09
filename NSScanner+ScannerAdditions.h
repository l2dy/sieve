//
//  NSScanner+ScannerAdditions.h
//  Sieve
//
//  Created by Sven Weidauer on 04.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScanner (ScannerAdditions) 
- (unichar) currentCharacter;
- (void) skipCharacter;

- (BOOL) scanLineTerminator;
- (BOOL) scanCharacterFromSet: (NSCharacterSet *) set intoChar: (unichar *) outChar;
- (BOOL) scanCharacter: (unichar) ch;
- (BOOL) scanNextCharacterIntoChar: (unichar *) outChar;

@end

