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

#import "ConnectionController.h"

#import "ServerWindowController.h"


@implementation ConnectionController

@synthesize openConnections;

static ConnectionController *sharedConnectionController = nil;

+ (ConnectionController *) sharedConnectionController;
{
    @synchronized( self ) {
        if (nil == sharedConnectionController) [[self alloc] init];
    }
    return sharedConnectionController;
}

+ (id) allocWithZone:(NSZone *)zone;
{
    @synchronized( self ) {
        if (nil == sharedConnectionController) {
            sharedConnectionController = [super allocWithZone: zone];
            return sharedConnectionController;
        }
    }
    return nil;
}

- (id) copyWithZone: (NSZone *) zone;
{
    return self;
}

- (NSUInteger) retainCount;
{
    return NSUIntegerMax;
}

- (void) release;
{
}

- (id) retain;
{
    return self;
}

- (id) autorelease;
{
    return self;
}

- (void) dealloc;
{
    [self setOpenConnections: nil];
    [super dealloc];
    sharedConnectionController = nil;
}

- (NSMutableDictionary *) openConnections;
{
    if (nil == openConnections) {
        openConnections = [[NSMutableDictionary alloc] init];
    }
    return openConnections;
}

- (ServerWindowController *) serverWindowForURL: (NSURL *) url;
{
    NSAssert( [[url scheme] isEqualToString: kSieveURLScheme], @"Only work with sieve URLs" );
    
    NSURL *rootUrl = [[NSURL URLWithString:@"/" relativeToURL: url] absoluteURL];
    
    ServerWindowController *controller = [[self openConnections] objectForKey: rootUrl];
    if (nil == controller) {
        controller = [[[ServerWindowController alloc] initWithURL: rootUrl] autorelease];
        [openConnections setObject: controller forKey: rootUrl];
    }
    
    return controller;
}

- (void) openURL: (NSURL *) url;
{
    if (nil == [url scheme]) {
        url = [NSURL fileURLWithPath: [url path]];
    }
    
    if ([url isFileURL]) {
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: url display: YES error: NULL];
    } else if ([[url scheme] isEqualToString: kSieveURLScheme]) {
        ServerWindowController *controller = [self serverWindowForURL: url];
        [controller openURL: url];
    } else {
        NSBeep();
    }
}

- (void) closeConnection: (ServerWindowController *) connection;
{
    NSURL *url = [connection baseURL];
    [[self openConnections] removeObjectForKey: url];
    NSLog( @"Closed connection %@", url );
    NSLog( @"Open connections: %@", [openConnections allKeys] );
}

@end
