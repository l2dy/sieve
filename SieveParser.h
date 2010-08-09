//
//  SieveParser.h
//  Sieve
//
//  Created by Sven Weidauer on 29.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SieveParser : NSObject {
    NSScanner *scanner;
}

@property (readwrite, retain) NSScanner *scanner;

- initWithString: (NSString *) string;

@end
