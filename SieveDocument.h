//
//  MyDocument.h
//  Sieve
//
//  Created by Sven Weidauer on 29.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@interface SieveDocument : NSDocument {
    NSString *script;
    NSString *result;
}

@property (readwrite, copy) NSString *script;
@property (readwrite, copy) NSString *result;

- (IBAction) parseScript: (id) sender;
@end
