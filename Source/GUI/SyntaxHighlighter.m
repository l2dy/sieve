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


#import "SyntaxHighlighter.h"
#import "NSScanner+ScannerAdditions.h"

@interface NSString (RangeTools) 
- (NSUInteger) indexOfCharactersFromSet:(NSCharacterSet *) charset beforePosition: (NSUInteger) pos;
- (NSUInteger) indexOfCharactersFromSet:(NSCharacterSet *) charset afterPosition: (NSUInteger) pos;

@end


@implementation NSString (RangeTools) 
- (NSUInteger) indexOfCharactersFromSet:(NSCharacterSet *) charset beforePosition: (NSUInteger) pos;
{
    NSRange range = NSMakeRange( 0, pos );
    NSRange result = [self rangeOfCharacterFromSet: charset options: NSBackwardsSearch range: range];
    return result.location;
}

- (NSUInteger) indexOfCharactersFromSet:(NSCharacterSet *) charset afterPosition: (NSUInteger) pos;
{
    NSRange range = NSMakeRange( pos, [self length] - pos );
    NSRange result = [self rangeOfCharacterFromSet: charset options: 0 range: range];
    return result.location;
}
@end

@implementation SyntaxHighlighter
- (void)awakeFromNib
{
    [[textView textStorage] setDelegate:self];
}

NSRange RangeToHighlight(NSTextStorage *textStorage) 
{
    NSRange editedRange = [textStorage editedRange];
    
    NSString *string = [textStorage string];
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    NSUInteger firstBefore = [string indexOfCharactersFromSet: ws beforePosition: editedRange.location];
    if (NSNotFound == firstBefore) firstBefore = 0;
    
    NSUInteger firstAfter = [string indexOfCharactersFromSet: ws afterPosition: NSMaxRange( editedRange )];
    if (NSNotFound == firstAfter) firstAfter = [string length];

    return NSMakeRange( firstBefore, firstAfter - firstBefore  );
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    NSTextStorage *textStorage = [notification object];
   
    [textStorage removeAttribute:NSForegroundColorAttributeName range: NSMakeRange( 0, [textStorage length] )];
    
    NSScanner *scanner = [NSScanner scannerWithString: [textStorage string]];
    [scanner setCaseSensitive: NO];
    [scanner setCharactersToBeSkipped: nil];
    
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    while (![scanner isAtEnd]) {
        [scanner scanCharactersFromSet: ws intoString: NULL];
        
        NSUInteger start = [scanner scanLocation];
        if ([scanner scanCharacter: '#']) {
            [scanner scanUpToCharactersFromSet: [NSCharacterSet newlineCharacterSet] intoString: NULL];
            [scanner scanLineTerminator];
            
            NSRange commentRange = NSMakeRange( start, [scanner scanLocation] - start );
            [textStorage addAttribute: NSForegroundColorAttributeName value: [NSColor darkGrayColor] range: commentRange];
        } else if ([scanner scanString: @"/*" intoString: NULL]) {
            [scanner scanUpToString: @"*/" intoString: NULL];
            [scanner scanString: @"*/" intoString: NULL];

            NSRange commentRange = NSMakeRange( start, [scanner scanLocation] - start  );
            [textStorage addAttribute: NSForegroundColorAttributeName value: [NSColor darkGrayColor] range: commentRange];
        } else if ([scanner scanCharacter: '"']) {
            while (true) {
                [scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @"\"\\"] intoString: NULL];
                unichar ch;
                if (![scanner scanNextCharacterIntoChar: &ch]) break;
                if (ch == '\\') [scanner scanNextCharacterIntoChar: &ch];
                else break;
            }
            NSRange commentRange = NSMakeRange( start, [scanner scanLocation] - start  );
            [textStorage addAttribute: NSForegroundColorAttributeName value: [NSColor blueColor] range: commentRange];
        } else if ([scanner scanString: @"text:" intoString: NULL]) {
            // multi-line-string
        }
        
        [scanner scanUpToCharactersFromSet: ws intoString: NULL];
    }
}

@end
