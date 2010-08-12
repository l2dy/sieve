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

#import "AppController.h"
#import "ServerWindowController.h"
#import "OpenURLController.h"

@interface AppController ()

- (void) handleGetURLEvent: (NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent;

@end

@implementation AppController

@synthesize openConnections;

- (void) dealloc;
{
    [self setOpenConnections: nil];
    [super dealloc];
}

- (NSMutableDictionary *) openConnections;
{
    if (nil == openConnections) {
        openConnections = [[NSMutableDictionary alloc] init];
    }
    return openConnections;
}

- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) 
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (ServerWindowController *) serverWindowForURL: (NSURL *) url;
{
    NSAssert( [[url scheme] isEqualToString: @"sieve"], @"Only work with sieve URLs" );
    
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
    } else if ([[url scheme] isEqualToString: @"sieve"]) {
        ServerWindowController *controller = [self serverWindowForURL: url];
        [controller openURL: url];
    } else {
        NSBeep();
    }
}

- (void) handleGetURLEvent: (NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent;
{
    NSURL *url = [NSURL URLWithString: [[event descriptorForKeyword: keyDirectObject] stringValue]];

    [self openURL: url];
}

- (IBAction) performOpenURL: (id) sender;
{
    [OpenURLController askForURLOnSuccess: ^(NSString *result) {
        NSURL *url = [NSURL URLWithString: result];
        [self openURL: url];
    }];
}

@end
