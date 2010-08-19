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

#import "PasswordPanelController.h"


@implementation PasswordPanelController

@synthesize user;
@synthesize password;
@synthesize save;

- init;
{
    return [super initWithWindowNibName: @"PasswordWindow"];
}

- (IBAction) acceptPassword: (id) sender;
{
    [controller commitEditing];
    [NSApp endSheet: [self window] returnCode: NSOKButton];
}

- (IBAction) cancelPassword: (id) sender;
{
    [controller discardEditing];
    [NSApp endSheet: [self window] returnCode: NSCancelButton];
}

- (NSURLCredential *) credentials;
{
    NSURLCredentialPersistence persistence = NSURLCredentialPersistenceForSession;
    if (save) persistence = NSURLCredentialPersistencePermanent;
    
    return [NSURLCredential credentialWithUser: user password: password persistence: persistence];
}

- (void) setCredentials: (NSURLCredential *) credentials;
{
    [self setUser: [credentials user]];
    if ([credentials hasPassword]) [self setPassword: [credentials password]];
    else [self setPassword: nil];
    [self setSave: [credentials persistence] == NSURLCredentialPersistencePermanent];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    [sheet orderOut: self];
    PasswordCompletionBlock block = contextInfo;
    if (nil != block) {
        block( returnCode == NSOKButton, self );
        [block release];
    }
}

- (void) beginSheetModalForWindow: (NSWindow *) window completionBlock: (PasswordCompletionBlock) block;
{
    [NSApp beginSheet: [self window] modalForWindow: window modalDelegate: self 
       didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: [block copy]];
}

@end
