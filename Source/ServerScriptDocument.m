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

#import "ServerScriptDocument.h"
#import "ServerWindowController.h"
#import "SieveClient.h"
#import "SaveToServerPanelController.h"

#import <objc/message.h>

@implementation ServerScriptDocument

@synthesize server;
@synthesize isProcessing;

- initWithServer: (ServerWindowController *) srv URL: (NSURL *) documentURL;
{
    if (nil == [super init]) return nil;
    
    [self setFileURL: documentURL];
    [self setFileType: kSieveScriptFileType];
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

- (void)didPresentErrorWithRecovery:(BOOL)didRecover  contextInfo:(void *)contextInfo;
{
}

typedef void (^SaveToURLBlock)( BOOL result, NSError *error );
- (void) saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)selector contextInfo:(void *)contextInfo;
{
    NSAssert( saveOperation != NSAutosaveOperation, @"I don't support autosave" );
    NSAssert( [typeName isEqualToString: kSieveScriptFileType], @"I only support sieve scripts" );
    
    [[self viewController] commitEditing];
    
    if ([url isFileURL]) {
        [super saveToURL:url ofType:typeName forSaveOperation:saveOperation delegate:delegate didSaveSelector: selector contextInfo: contextInfo];        
    } else {
        NSAssert( [[url scheme] isEqualToString: kSieveURLScheme], @"Support only SIEVE URLs" );
        
        SaveToURLBlock block = [^(BOOL result, NSError *error){
            if (result) {
                [self updateChangeCount: NSChangeCleared];
                if (nil == [self fileURL] || NSSaveAsOperation == saveOperation) {
                    [self setFileURL: url];
                }
            } else {
                [self presentError: error modalForWindow: [self windowForSheet] delegate: self didPresentSelector: @selector(didPresentErrorWithRecovery:contextInfo:) contextInfo: NULL];
            }
            ((void (*)( id, SEL, id, BOOL, void *))objc_msgSend)( delegate, selector, self, result, contextInfo );
        } copy];
        
        [[server client] putScript: [self script] withName: [url lastPathComponent] delegate: self userInfo: block];
    }
}


- (void) sieveClient: (SieveClient *) client failedToSaveScript: (NSString *) name withError: (NSError *) error contextInfo: (void *)ci;
{
    NSParameterAssert( NULL != ci );
    
    SaveToURLBlock block = (SaveToURLBlock)ci;
    block( NO, error );
    [block release];
}

- (void) sieveClient: (SieveClient *) client savedScript: (NSString *) name contextInfo: (void *)ci;
{
    NSParameterAssert( NULL != ci );

    SaveToURLBlock block = (SaveToURLBlock)ci;
    block( YES, nil );
    [block release];
    
    [server sieveClient: client savedScript: name contextInfo: ci];
}

- (void) tryCloseWithBlock: (void (^)( BOOL )) block;
{
    [server windowShouldCloseWithBlock: ^(BOOL shouldClose) {
        if (shouldClose) [server close];
        block( shouldClose );;
    }];
}


- (void) runModalSavePanelForSaveOperation:(NSSaveOperationType)saveOperation delegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo;
{
    if (saveOperation == NSSaveToOperation) {
        [super runModalSavePanelForSaveOperation: saveOperation delegate: delegate didSaveSelector: didSaveSelector contextInfo: contextInfo];
        return;
    }
    
    SaveToServerPanelController *savePanel = [[SaveToServerPanelController alloc] init];
    [savePanel beginSheetModalForWindow: [self windowForSheet] completionBlock: ^( NSInteger rc, NSString *name) {
        if (NSOKButton == rc) {
            NSURL *newURL = [[server baseURL] URLByAppendingPathComponent: name];
            [self saveToURL: newURL ofType: kSieveScriptFileType forSaveOperation: saveOperation delegate: delegate didSaveSelector:didSaveSelector contextInfo: contextInfo];
        } else {
            BOOL result = NO;
            ((void (*)(id, SEL, id, BOOL, void *))objc_msgSend)( delegate, didSaveSelector, self, result, contextInfo );
        }
        [savePanel release];
    }];
}

- (void) close;
{
    [self removeWindowController: server];
    [super close];
}

@end
