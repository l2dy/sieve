//
//  MyDocument.m
//  Sieve
//
//  Created by Sven Weidauer on 29.07.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SieveDocument.h"
#import "SieveParser.h"

@implementation SieveDocument

@synthesize script, result;

- (id)init
{
    self = [super init];
    if (self) {
    
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"SieveDocument";
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}


- (IBAction) parseScript: (id) sender;
{
    SieveParser *parser = [[[SieveParser alloc] initWithString: [self script]] autorelease];
    [self setResult: [[parser commands] description]];
}

@end
