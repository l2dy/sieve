//
//  main.m
//  Sieve
//
//  Created by Sven Weidauer on 29.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SieveParser.h"

int main(int argc, char *argv[])
{
#if 0
    [[NSAutoreleasePool alloc] init];
    NSString *string = @"# geblubber\n require/* bla */  [\"a\",\"b\"];\n\nif # test 1\n allof( anyof( not header :contains text:\na\n..\n..xb\n.bla\n\n.\r\n [\"b\\\"\\\\\", \"c\"], true ), false ) { reject; if false { keep ; } elsif true { break; } else { stop ; } }";
    SieveParser *p = [[[SieveParser alloc] initWithString: string] autorelease];
    id c = [p commands];
    NSLog( @"parsed: %@", c );
    
    return 0;
#else
    return NSApplicationMain(argc, (const char **) argv);
#endif
}
