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


#import "PreferencesWindowController.h"
#import "AccountList.h"
#import "Account.h"
#import "CreateAccountWindowController.h"

#import <objc/objc-runtime.h>

@implementation PreferencesWindowController

@synthesize tabs;
@synthesize accountArrayController;

- init;
{
    self = [super initWithWindowNibName: @"PreferencesWindow"];
    if (nil == self) {
        return nil;
    }
    
    accountList = [AccountList sharedAccountList];
    
    return self;
}

- (IBAction) selectPanel: (id) sender;
{
    [tabs selectTabViewItemAtIndex: [sender tag]];
}

- (IBAction) newAccount: (id) sender;
{
    [[[CreateAccountWindowController alloc] init] runAsSheetForWindow: [self window]];
}

- (IBAction) deleteAccount: (id) sender;
{
    NSIndexSet *selectedIndices = [accountArrayController selectionIndexes];
    [selectedIndices enumerateIndexesWithOptions: NSEnumerationReverse 
                                      usingBlock: ^( NSUInteger index, BOOL *stop ) {
        Account *account = [accountList objectInAccountsAtIndex: index];
        NSError *error = nil;
        BOOL deleted = [account deletePresetFileError: &error];
        if (!deleted) {
            if (nil != error) {
                [self presentError: error modalForWindow: [self window] delegate: self didPresentSelector: @selector(didPresentErrorWithRecovery:contextInfo:) contextInfo: NULL];
            }
            *stop = YES;
        } else {
            [accountList removeObjectFromAccountsAtIndex: index];
        }
    }];
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo;
{
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
    NSUInteger selectedRow = [accountArrayController selectionIndex];
    if (NSNotFound == selectedRow) {
        return YES;
    }
    
    Account *account = [[accountArrayController arrangedObjects] objectAtIndex: selectedRow];
    
    if ([account dirty]) {
        NSString *message = [NSString stringWithFormat: NSLocalizedString( @"Do you want to save the changes to the account '%@'?", @"" ), [account accountName]];
        NSAlert *alert = [NSAlert alertWithMessageText: message 
                                         defaultButton: NSLocalizedString( @"Save", @"Save button" ) 
                                       alternateButton: NSLocalizedString( @"Don’t save", @"Don’t save button" )
                                           otherButton: NSLocalizedString( @"Cancel", @"Cancel button" ) 
                             informativeTextWithFormat: NSLocalizedString( @"If you don’t save your changes are getting lost.", @"" )];
        [alert beginSheetModalForWindow: [self window] modalDelegate: self 
                         didEndSelector: @selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo: (void *)rowIndex];
        return NO;
    }
    
    return YES;
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    SEL op = NULL;
    switch (returnCode) {
        case NSAlertDefaultReturn:
            op = @selector( saveError: );
            break;
            
        case NSAlertAlternateReturn:
            op = @selector( loadError: );
            break;
            
        case NSAlertOtherReturn:
            return;
    }

    NSUInteger selectedRow = [accountArrayController selectionIndex];
    Account *account = [[accountArrayController arrangedObjects] objectAtIndex: selectedRow];
    
    NSError *error = nil;
    BOOL success = ((BOOL (*)(id,SEL,NSError **))objc_msgSend)( account, op, &error );
    if (success) {
        [accountArrayController setSelectionIndex: (NSUInteger)contextInfo];
    } else {
        [self presentError: error modalForWindow: [self window] 
                  delegate: self didPresentSelector: @selector(didPresentErrorWithRecovery:contextInfo:) 
               contextInfo: NULL];
    }
}

- (void) windowDidLoad;
{
    [[[self window] toolbar] setSelectedItemIdentifier: @"accounts" ];
}

@end
