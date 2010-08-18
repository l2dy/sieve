//
//  SaveToServerPanelController.m
//  Sieve
//
//  Created by Sven Weidauer on 18.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
    [NSApp endSheet: [self window] returnCode: NSOKButton];
}

- (IBAction) cancelClicked: (id) sender;
{
    [objectController discardEditing];
    [NSApp endSheet: [self window] returnCode: NSCancelButton];
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
