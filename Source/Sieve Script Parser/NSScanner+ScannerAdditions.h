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


/*! Additional methods for NSScanner
 */
@interface NSScanner (ScannerAdditions) 

/*! Returns the character at the current scan location. Must not be called if scanner is at end.
 */
- (unichar) currentCharacter;

/*! Moves the scan location one character ahead
 */
- (void) skipCharacter;


/*! Scans a line terminator. Either a single CR, a single LF, a CRLF pair or one of the other Unicode
 *  line separators
 */
- (BOOL) scanLineTerminator;

/*! Scans a single character from the character set set
 *  @param set      [in]    characters to accept
 *  @param outChar  [out]   pointer to an unichar to receive the scanned character. May be NULL
 *  @result         YES if a matching character was read, NO otherwise
 */
- (BOOL) scanCharacterFromSet: (NSCharacterSet *) set intoChar: (unichar *) outChar;

/*! Returns YES if the character ch was the next character, otherwise NO 
 */
- (BOOL) scanCharacter: (unichar) ch;

/*! Retrieves the next character from the string
 *  @param outChar  [out]   pointer to an unichar to receive the scanned character. May be NULL
 *  @result         YES if a character was read, NO otherwise
 */
- (BOOL) scanNextCharacterIntoChar: (unichar *) outChar;

@end

