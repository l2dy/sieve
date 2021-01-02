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

#import "SaveToServerPanelController.h"


@implementation SaveToServerPanelController

@synthesize result;

- init;
{
    self = [super initWithWindowNibName: @"SaveToServerPanel"];
    [self setResult: @""];
    return self;
}

- (IBAction) saveClicked: (id) sender;
{
    [objectController commitEditing];
    [NSApp endSheet: [self window] returnCode: NSModalResponseOK];
}

- (IBAction) cancelClicked: (id) sender;
{
    [objectController discardEditing];
    [NSApp endSheet: [self window] returnCode: NSModalResponseCancel];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    [sheet orderOut: self];
    SaveCompletionBlock block = (SaveCompletionBlock) contextInfo;
    if (nil != block) {
        block( returnCode, [self result] );
        [block release];
    }
}

- (void) beginSheetModalForWindow: (NSWindow *) window completionBlock: (SaveCompletionBlock) block;
{
    [NSApp beginSheet: [self window] modalForWindow: window modalDelegate: self 
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: (void *)[block copy] ];
}

@end
