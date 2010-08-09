//
//  SyntaxHighlighter.m
//  Sieve
//
//  Created by Sven Weidauer on 05.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
