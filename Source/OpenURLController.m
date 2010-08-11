//
//  OpenURLController.m
//  Sieve
//
//  Created by Sven Weidauer on 11.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

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
    [[self window] close];
}

- (void) dealloc;
{
    [successBlock release];
    [super dealloc];
}

@end
