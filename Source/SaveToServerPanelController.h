//
//  SaveToServerPanelController.h
//  Sieve
//
//  Created by Sven Weidauer on 18.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef void (^SaveCompletionBlock)( NSInteger returnCode, NSString *name );

@interface SaveToServerPanelController : NSWindowController {
    NSString *result;
    IBOutlet NSObjectController *objectController;
}

@property (readwrite, copy) NSString *result;

- (IBAction) saveClicked: (id) sender;
- (IBAction) cancelClicked: (id) sender;

- (void) beginSheetModalForWindow: (NSWindow *) window completionBlock: (SaveCompletionBlock) block;

@end
