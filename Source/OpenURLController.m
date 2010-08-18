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

#import "OpenURLController.h"


@implementation OpenURLController

+ (void) askForURLOnSuccess: (void (^)( NSString *result )) successBlock;
{
    OpenURLController *controller = [[self alloc] initWithSuccessBlock: successBlock];
    [[controller window] makeKeyAndOrderFront: self];
}

- initWithSuccessBlock: (void (^)( NSString *result )) block;
{
    if (nil == [super initWithWindowNibName: @"OpenURLWindow"]) return nil;

    successBlock = [block copy];
    
    return self;
}

- (IBAction) openClicked: (id) sender;
{
    [objectController commitEditing];
    
    while (true) {
        NSInteger oldIndex = [[historyArray arrangedObjects] indexOfObject: currentString];
        if (oldIndex == NSNotFound) break;
        [historyArray removeObjectAtArrangedObjectIndex: oldIndex];
    }
    
    [historyArray insertObject: currentString atArrangedObjectIndex: 0];
 
    // TODO: Find out how many entries are kept in the open recent menu
    const int KeepEntries = 10;
    int count = [[historyArray arrangedObjects] count];
    if (count > KeepEntries) {
        [historyArray removeObjectsAtArrangedObjectIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange( KeepEntries, count - KeepEntries )]];
    }
    
    [[self window] close];
    
    successBlock( currentString );
}

- (IBAction) cancelClicked: (id) sender;
{
    [objectController discardEditing];
    
    [[self window] close];
}

- (void) dealloc;
{
    [successBlock release];
    [super dealloc];
}

@end
