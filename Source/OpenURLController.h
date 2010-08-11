//
//  OpenURLController.h
//  Sieve
//
//  Created by Sven Weidauer on 11.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface OpenURLController : NSWindowController {
    NSString *currentString;
    IBOutlet NSArrayController *historyArray;
    void (^successBlock)( NSString *result );
}

+ (void) askForURLOnSuccess: (void (^)( NSString *result )) successBlock;

- initWithSuccessBlock: (void (^)( NSString *result )) successBlock;

- (IBAction) openClicked: (id) sender;
- (IBAction) cancelClicked: (id) sender;

@end
