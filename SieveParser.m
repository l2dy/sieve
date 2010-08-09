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


#import "SieveParser.h"
#import "NSScanner+ScannerAdditions.h"

@interface NSCharacterSet (IdentifierSets) 

+ (NSCharacterSet *) beginIdentifierSet;
+ (NSCharacterSet *) identifierSet;
+ (NSCharacterSet *) unitSuffixSet;

@end

@implementation NSCharacterSet (IdentifierSets) 

+ (NSCharacterSet *) beginIdentifierSet;
{
    static NSCharacterSet *result = nil;
    @synchronized( self ) {
        if (nil == result) {
            NSMutableCharacterSet *builder = [NSMutableCharacterSet characterSetWithCharactersInString: @"_"];
            [builder addCharactersInRange: NSMakeRange( 'a', 'z' - 'a' )];
            [builder addCharactersInRange: NSMakeRange( 'A', 'Z' - 'A' )];
            result = [builder copy];
        }        
    } 
    return result;
}

+ (NSCharacterSet *) identifierSet;
{
    static NSCharacterSet *result = nil;
    @synchronized( self ) {
        if (nil == result) {
            NSMutableCharacterSet *builder = [[[self beginIdentifierSet] mutableCopy] autorelease];
            [builder addCharactersInRange: NSMakeRange( '0', '9' - '0' )];
            result = [builder copy];
        }        
    }
    return result;
}


+ (NSCharacterSet *) unitSuffixSet;
{
    static NSCharacterSet *result = nil;
    @synchronized( self ) {
        if (nil == result) {
            result = [[NSCharacterSet characterSetWithCharactersInString: @"kKmMgG"] retain];
        }
    }
    return result;
}

@end


@interface SieveParser ()
- (void) skipWhitespaceAndComments;


- (id) commands;
- (id) command;
- (id) params;
- (id) param;
- (id) stringList;
- (id) testBlock;
- (id) ifBlock;
- (id) block;
- (id) test;
- (id) testList;

@end

@implementation SieveParser


@synthesize scanner;

- initWithString: (NSString *) string;
{
    if (nil == [super init]) return nil;
    
    [self setScanner: [NSScanner scannerWithString: string]];
    [scanner setCharactersToBeSkipped: nil];
    [scanner setCaseSensitive: NO];
    
    [self skipWhitespaceAndComments];
    
    return self;
}

- (void) skipWhitespaceAndComments;
{
    NSCharacterSet *wsSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    while (true) {
        if ([scanner scanCharactersFromSet: wsSet intoString: NULL]) {
            // do nothing
        } else if ([scanner scanString: @"#" intoString: NULL]) {
            NSCharacterSet *nlSet = [NSCharacterSet newlineCharacterSet];
            [scanner scanUpToCharactersFromSet: nlSet intoString: NULL];
            [scanner scanLineTerminator];
        } else if ([scanner scanString: @"/*" intoString: NULL]) {
            [scanner scanUpToString: @"*/" intoString: NULL];
            [scanner scanString: @"*/" intoString: NULL];
        } else {
            break;
        }
    }    
}

- (bool) acceptToken: (NSString *) token;
{
    bool result = [scanner scanString: token intoString: NULL];
    if (result) [self skipWhitespaceAndComments];
    return result;
}

- (bool) parseSimpleString: (NSString **) outString;
{
    NSCharacterSet *terminatorSet =  [NSCharacterSet characterSetWithCharactersInString: @"\"\\"];
    NSMutableString *result = [NSMutableString string];
    while (true) {
        NSString *part = nil;
        if ([scanner scanUpToCharactersFromSet: terminatorSet intoString: &part]) {
            [result appendString: part];
        }
        
        if ([scanner scanCharacter: '\\']) {
            unichar nextChar;
            if ([scanner scanNextCharacterIntoChar: &nextChar]) {
                [result appendFormat: @"%C", nextChar];
            } else {
                // error: invalid or no escaped character
                NSLog( @"Invalid or no next character" );
                break;
            }
        } else if ([scanner scanCharacter: '"']) {
            break;
        }
    }
    
    [self skipWhitespaceAndComments];

    if (outString) *outString = result;

    return true;
}

- (bool) parseMultilineString: (NSString **) outString;
{
    NSCharacterSet *nlSet = [NSCharacterSet newlineCharacterSet];

    [scanner scanUpToCharactersFromSet: nlSet intoString: NULL];
    [scanner scanLineTerminator];

    NSMutableString *result = [NSMutableString string];
    while (true) {
        NSString *part = @"";
        [scanner scanUpToCharactersFromSet: nlSet intoString: &part];
        [scanner scanLineTerminator];
        
        if ([part isEqualToString: @"."]) break;
        else {
            if ([part length] >= 2 && [part characterAtIndex: 0] == '.' && [part characterAtIndex: 1] == '.') part = [part substringFromIndex: 1];
            [result appendFormat: @"%@\n", part];                
        }
        
        if ([scanner isAtEnd]) {
            // error: am ende bevor string fertig
            NSLog( @"am ende bevor fertig" );
            break;
        }
    }
    
    [self skipWhitespaceAndComments];
    
    if (outString) *outString = result;
    
    return true;
}

- (bool) acceptString: (NSString **) outString;
{
    if ([scanner scanCharacter: '"']) return [self parseSimpleString: outString];
    if ([self acceptToken: @"text:"]) return [self parseMultilineString: outString];
    return false;
}

- (bool) acceptIdentifier: (NSString **) outIdentifier;
{
    unichar firstChar;
    if (![scanner scanCharacterFromSet: [NSCharacterSet beginIdentifierSet] intoChar: &firstChar]) return false;
    
    
    NSString *rest = @"";
    [scanner scanCharactersFromSet: [NSCharacterSet identifierSet] intoString: &rest];
    
    [self skipWhitespaceAndComments];
    
    if (outIdentifier) *outIdentifier = [NSString stringWithFormat: @"%C%@", firstChar, rest];
    
    return true;
}

- (bool) acceptTag: (NSString **) outTag;
{
    if (![scanner scanCharacter: ':']) return false;
    
    NSString *identifier = nil;
    if (![self acceptIdentifier: &identifier]) {
        NSLog( @"error: expected identifier" );
        return false;
    }
    
    if (outTag) *outTag = [NSString stringWithFormat: @":%@", identifier];
    return true;
}

- (bool) acceptNumber: (NSString **) outNumber;
{
    NSString *result = nil;
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    if (![scanner scanCharactersFromSet: digits intoString: &result]) return false;
    
    unichar suffix;
    if ([scanner scanCharacterFromSet: [NSCharacterSet unitSuffixSet] intoChar: &suffix]) {
        result = [result stringByAppendingFormat: @"%C", suffix];
    }
    
    [self skipWhitespaceAndComments];
    
    if (outNumber) *outNumber = result;
    
    return true;
}


- (id) commands;
{
    NSMutableArray *result = [NSMutableArray array];
    while (true) {
        id command = [self command];
        if (nil == command) break;
        [result addObject: command];
    }
    return result;
}


- (id) command;
{
    
    if ([self acceptToken: @"if"]) return [self ifBlock];

    NSString *ident = nil;
    if ([self acceptIdentifier: &ident]) {
        id params = [self params];
        if (![self acceptToken: @";"]) {
            NSLog( @"error: expected ';'" );
            return nil;
        }
        
        return [NSDictionary dictionaryWithObjectsAndKeys: ident, @"command", params,  @"parameters", nil];
    } 
    
    return nil;
}

- (id) params;
{
    NSMutableArray *result = [NSMutableArray array];
    while (true) {
        id param = [self param];
        if (nil == param) break;
        [result addObject: param];
    }
    return result;
}

- (id) param;
{
    NSString *result = nil;
    if ([self acceptTag: &result]) return result;
    if ([self acceptNumber: &result]) return result;
    if ([self acceptString: &result]) return result;
    if ([self acceptToken: @"["]) return [self stringList];
    
    return nil;
}

- (id) stringList;
{
    NSMutableArray *result = [NSMutableArray array];
    do {
        NSString *string = nil;
        if (![self acceptString: &string]) {
            NSLog( @"error: expected string" );
            return nil;
        }
        [result addObject: string];
    } while ([self acceptToken: @","]);
    if (![self acceptToken: @"]"]) {
        NSLog( @"error: expected ']'" );
        return nil;
    }
    return result;
}

- (id) testBlock;
{
    id test = [self test];
    id block = [self block];
    
    return [NSDictionary dictionaryWithObjectsAndKeys: test, @"test", block, @"block", nil];
}

- (id) ifBlock;
{
    NSMutableArray *tests = [NSMutableArray array];
    [tests addObject: [self testBlock]];
    while ([self acceptToken: @"elsif"]) {
        [tests addObject: [self testBlock]];
    }
    
    id elseBlock;
    if ([self acceptToken: @"else"]) elseBlock = [self block];
    else elseBlock = [NSNull null];
    
    return [NSDictionary dictionaryWithObjectsAndKeys: tests, @"tests", elseBlock, @"else", @"if", @"command", nil ];
}

- (id) block;
{
    if (![self acceptToken: @"{"]) {
        NSLog( @"error: expected block" );
        return nil;
    }
    
    id result = [self commands];
    
    if (![self acceptToken: @"}"]) {
        NSLog( @"error: expected '}'" );
        return nil;
    }
    
    return result;
}

- (id) test;
{
    if ([self acceptToken: @"not"]) {
        id test = [self test];
        return [NSDictionary dictionaryWithObjectsAndKeys: @"not", @"test", test, @"child", nil];
    }
    
    if ([self acceptToken: @"allof"]) {
        id tests = [self testList];
        return [NSDictionary dictionaryWithObjectsAndKeys: @"allof", @"test", tests, @"children", nil];
    }

    if ([self acceptToken: @"anyof"]) {
        id tests = [self testList];
        return [NSDictionary dictionaryWithObjectsAndKeys: @"anyof", @"test", tests, @"children", nil];
    }
    
    NSString *ident;
    if ([self acceptIdentifier: &ident]) {
        id params = [self params];
        return [NSDictionary dictionaryWithObjectsAndKeys: ident, @"test", params, @"parameters", nil];
    }

    NSLog( @"error: expected test" );
    return nil;
}

- (id) testList;
{
    if (![self acceptToken: @"("]) {
        NSLog( @"error: expected test-list" );
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray array];
    do {
        id test = [self test];
        [result addObject: test];
    } while ([self acceptToken: @","]);
    
    if (![self acceptToken: @")"]) {
        NSLog( @"error: expected ')'" );
        return nil;
    }
    
    return result;
}

@end
