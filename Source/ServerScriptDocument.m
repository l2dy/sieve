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

#import "ServerScriptDocument.h"
#import "ServerWindowController.h"
#import "SieveClient.h"

@implementation ServerScriptDocument

@synthesize server;
@synthesize isProcessing;

- initWithServer: (ServerWindowController *) srv URL: (NSURL *) documentURL;
{
    if (nil == [super init]) return nil;
    
    [self setFileURL: documentURL];
    [self setFileType: @"SieveScript"];
    [self setServer: srv];
    
    return self;
}

- (void) beginDownload;
{
    [self setIsProcessing: YES];
}

- (void) finnishedDownload: (NSString *) newScript;
{
    [self setScript: newScript];
    [self setIsProcessing: NO];
}

- (BOOL) isEdited;
{
    return [self isDocumentEdited];
}

- (void) updateChangeCount:(NSDocumentChangeType)change;
{
    [self willChangeValueForKey: @"isEdited"];
    [super updateChangeCount: change];
    [self didChangeValueForKey: @"isEdited"];
}

- (NSWindow *) windowForSheet;
{
    return [server window];
}

- (void) saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)selector contextInfo:(void *)contextInfo;
{
    NSAssert( saveOperation != NSAutosaveOperation, @"I don't support autosave" );
    
    if ([url isFileURL]) {
        [self saveToURL:url ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector: selector contextInfo: contextInfo];        
    } else {
        NSAssert( [[url scheme] isEqualToString: @"sieve"], @"Support only SIEVE URLs" );
        
        NSInvocation *delegateInvocation = [NSInvocation invocationWithMethodSignature: [delegate methodSignatureForSelector: selector]];
        [delegateInvocation setTarget: delegate];
        [delegateInvocation setSelector: selector];
        [delegateInvocation setArgument: &self atIndex: 2];
        [delegateInvocation setArgument: &contextInfo atIndex:4];
        [delegateInvocation retainArguments];
        [delegateInvocation retain];
        
        [[server client] putScript: [self script] withName: [url lastPathComponent] delegate: self userInfo: delegateInvocation];
    }
}


- (void) sieveClient: (SieveClient *) client failedToSaveScript: (NSString *) name withError: (NSError *) error contextInfo: (void *)ci;
{
    NSLog( @"Error saving script %@: %@", name, error );
    
    NSInvocation *delegateInvocation = ci;
    BOOL result = NO;
    [delegateInvocation setArgument: &result atIndex: 3];
    [delegateInvocation invoke];
    [delegateInvocation release];
}

- (void) sieveClient: (SieveClient *) client savedScript: (NSString *) name contextInfo: (void *)ci;
{
    NSLog( @"Successfully saved script %@", name );
    
    NSInvocation *delegateInvocation = ci;
    BOOL result = YES;
    [delegateInvocation setArgument: &result atIndex: 3];
    [delegateInvocation invoke];
    [delegateInvocation release];
}

@end
