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

@synthesize client;
@synthesize delegate;
@synthesize userInfo;


- initForClient: (SieveClient *) newClient delegate: (id) newDelegate userInfo: (void *) newUserInfo;
{
    if (nil == [super init]) return nil;
    
    [self setClient: newClient];
    
    if (NULL != newDelegate) [self setDelegate: newDelegate];
    else [self setDelegate: [newClient delegate]];
    
    [self setUserInfo: newUserInfo];
    
    return self;
    
}

- initForClient: (SieveClient *) newClient;
{
    return [self initForClient: newClient delegate: NULL userInfo: NULL];
}

- (NSString *) command;
{
    return @"NOOP";
}

- (void) start;
{
    [client send: [self command] completion: ^( NSDictionary *response) {
        [self receivedResponse: response];
    }];
}

- (void) receivedSuccessResponse: (NSDictionary *) response;
{
    
}

- (void) receivedFailureResponse: (NSDictionary *) response;
{
    if ([delegate respondsToSelector: @selector( sieveClient:failedOperationWithError:contextInfo: )]) {
        NSError *error = [self errorForResponse: response];
        [delegate sieveClient: client failedOperationWithError: error contextInfo: userInfo];
    }
}

- (void) receivedResponse: (NSDictionary *) response;
{
    if ([[response objectForKey: @"responseCode"] isEqualToString: @"OK"]) [self receivedSuccessResponse: response];
    else [self receivedFailureResponse: response];
    
    [client startNextOperation];
}

- (NSError *) errorForResponse: (NSDictionary *) response;
{
    return nil;
}

@end

@implementation  SieveListScriptsOperation

- (void) receivedSuccessResponse: (NSDictionary *) response;
{
    id delegate = [self delegate];
    
    if ([delegate respondsToSelector: @selector(sieveClient:retrievedScriptList:active:contextInfo:)]) {
        
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
        
        [delegate sieveClient: [self client] retrievedScriptList: scriptNames active: activeScript contextInfo: [self userInfo]];
    }
}

- (NSString *) command;
{
    return @"LISTSCRIPTS";
}

@end


@implementation  SieveGetScriptOperation

@synthesize scriptName;

- initWithScript: (NSString *) script forClient: (SieveClient *) client  delegate: (id) delegate userInfo: (void *) userInfo;
{
    if (nil == [super initForClient: client delegate: delegate userInfo: userInfo]) return nil;
    [self setScriptName: script];
    return self;
}

- (NSString *) command;
{
    return [NSString stringWithFormat: @"GETSCRIPT \"%@\"", scriptName];
}

- (void) receivedSuccessResponse: (NSDictionary *) response;
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector: @selector( sieveClient:retrievedScript:withName:contextInfo: )]) {
        [delegate sieveClient: [self client] retrievedScript: [[response objectForKey: @"response"] objectAtIndex: 0] withName: scriptName contextInfo: [self userInfo]];
    }
}

- (void) dealloc;
{
    [self setScriptName: nil];
    [super dealloc];
}

@end


@implementation SieveDeleteScriptOperation

@synthesize scriptName;

- (id) initWithScript:(NSString *)script forClient:(SieveClient *)client delegate: (id) delegate userInfo: (void *) userInfo;
{
    if (nil == [super initForClient: client delegate: delegate userInfo: userInfo]) return nil;
    [self setScriptName: script];
    return self;
}

- (NSString *) command;
{
    return [NSString stringWithFormat: @"DELETESCRIPT \"%@\"", scriptName];
}

- (void) receivedSuccessResponse:(NSDictionary *)response;
{
    if ([[self delegate] respondsToSelector: @selector( sieveClient:deletedScript:contextInfo: )]) {
        [[self delegate] sieveClient: [self client] deletedScript: scriptName contextInfo: [self userInfo]];
    }
}

@end

@implementation SieveSetActiveOperation

@synthesize scriptName;

- (id) initWithScript:(NSString *)script forClient:(SieveClient *)client delegate: (id) delegate userInfo: (void *) userInfo;
{
    if (nil == [super initForClient: client delegate: delegate userInfo: userInfo]) return nil;
    [self setScriptName: script];
    return self;
}

- (NSString *) command;
{
    return [NSString stringWithFormat: @"SETACTIVE \"%@\"", scriptName];
}

- (void) receivedSuccessResponse:(NSDictionary *)response;
{
    if ([[self delegate] respondsToSelector: @selector( sieveClient:activatedScript:contextInfo: )]) {
        [[self delegate] sieveClient:[self client] activatedScript: scriptName contextInfo: [self userInfo]];
    }
}

@end


@implementation SieveRenameScriptOperation 

@synthesize oldName, newName;

- initWithOldName:(NSString *)from newName:(NSString *)to forClient:(SieveClient *)client  delegate: (id) delegate userInfo: (void *) userInfo;
{
    if (nil == [super initForClient: client  delegate: delegate userInfo: userInfo]) return nil;
    [self setOldName: from];
    [self setNewName: to];
    return self;
}


- (NSString *) command;
{
    return [NSString stringWithFormat: @"RENAMESCRIPT \"%@\" \"%@\"", oldName, newName];
}

- (void) receivedSuccessResponse:(NSDictionary *)response;
{
    if ([[self delegate] respondsToSelector: @selector(sieveClient:renamedScript:to:contextInfo:)]) {
        [[self delegate] sieveClient:[self client] renamedScript: oldName to: newName contextInfo: [self userInfo]];
    }
}

@end

@implementation SievePutScriptOperation

@synthesize script, scriptName;

- initWithScript:(NSString *)scriptString name:(NSString *)name forClient:(SieveClient *)client delegate: (id) delegate userInfo: (void *) userInfo;
{
    if (nil == [super initForClient: client delegate: delegate userInfo: userInfo]) return nil;
    
    [self setScriptName: name];
    [self setScript: [scriptString dataUsingEncoding: NSUTF8StringEncoding]];
   
    return self;
}

- (void) receivedHaveSpaceResponse: (NSDictionary *) response;
{
    if ([[response objectForKey: @"responseCode"] isEqualToString: @"OK"]) {
        NSString *sendCommand = [NSString stringWithFormat: @"PUTSCRIPT \"%@\" {%d}", scriptName, [script length]];
        
        SieveClient *client = [self client];
        
        [client logLine: sendCommand from: @"Client"];
        
        [client sendData: [sendCommand dataUsingEncoding: NSUTF8StringEncoding]];
        [client sendData: [AsyncSocket CRLFData]];
        [client sendData: script];
        [client sendData: [AsyncSocket CRLFData]];
        
        [client receiveResponse: ^(NSDictionary *response) {
            [self receivedResponse: response];
        }];
        
    } else {
        [self receivedResponse: response];
    }
}

- (void) receivedSuccessResponse:(NSDictionary *)response;
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector: @selector( sieveClient:savedScript:contextInfo: )]) {
        [delegate sieveClient: [self client] savedScript: scriptName contextInfo: [self userInfo]];
    }
}

- (void) receivedFailureResponse:(NSDictionary *)response;
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector: @selector( sieveClient:failedToSaveScript:withError:contextInfo: )]) {
        [delegate sieveClient: [self client] failedToSaveScript: scriptName withError:nil contextInfo: [self userInfo]];
    }
}

- (void) start;
{
    NSString *command = [NSString stringWithFormat: @"HAVESPACE \"%@\" %d", scriptName, [script length]];
    [[self client] send: command completion: ^( NSDictionary *response) {
        [self receivedHaveSpaceResponse: response];
    }];
}


@end
