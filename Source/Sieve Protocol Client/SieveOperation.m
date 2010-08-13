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

#import "SieveOperation.h"
#import "SieveClientInternals.h"
#import "NSScanner+QuotedString.h"

@implementation SieveOperation

@synthesize command;
@synthesize client;

- initWithCommand: (NSString *) newCommand forClient: (SieveClient *) newClient;
{
    if (nil == [super init]) return nil;
    
    [self setClient: newClient];
    [self setCommand: newCommand];
    
    return self;
}

- initForClient: (SieveClient *) newClient;
{
    return [self initWithCommand: nil forClient: newClient];
}

- (void) start;
{
    [client send: command completion: ^( NSDictionary *response) {
        [self receivedResponse: response];
    }];
}

- (void) receivedResponse: (NSDictionary *) response;
{
    [client startNextOperation];
}

@end

@implementation  SieveListScriptsOperation

- initForClient: (SieveClient *) newClient;
{
    return [super initWithCommand: @"LISTSCRIPTS" forClient: newClient];
}

- (void) receivedResponse: (NSDictionary *) response;
{
    if ([[response objectForKey: @"responseCode"] isEqualToString: @"OK"]) {
        id <SieveClientDelegate> delegate = [client delegate];
        
        if ([delegate respondsToSelector: @selector(sieveClient:retrievedScriptList:active:)]) {
            
            NSArray *responseLines = [response objectForKey: @"response"];
            NSString *activeScript = nil;
            NSMutableArray *scriptNames = [NSMutableArray arrayWithCapacity: [responseLines count]];
            for (NSString *line in responseLines) {
                NSScanner *scanner = [NSScanner scannerWithString: line];
                [scanner setCaseSensitive: NO];
                
                NSString *scriptName = nil;
                if ([scanner scanQuotedString: &scriptName]) {
                    [scriptNames addObject: scriptName];
                    if ([scanner scanString: @"ACTIVE" intoString: NULL]) {
                        activeScript = scriptName;
                    }
                }
            }
            
            [delegate sieveClient: client retrievedScriptList: scriptNames active: activeScript];
        }
    }

    [super receivedResponse: response];
}

@end

