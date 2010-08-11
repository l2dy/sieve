//
//  AppController.m
//  Sieve
//
//  Created by Sven Weidauer on 11.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"

@interface AppController ()

- (void) handleGetURLEvent: (NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent;

@end

@implementation AppController


- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) 
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}


- (void) handleGetURLEvent: (NSAppleEventDescriptor *)event withReplyEvent: (NSAppleEventDescriptor *)replyEvent;
{
    NSURL *url = [NSURL URLWithString: [[event descriptorForKeyword: keyDirectObject] stringValue]];
    NSLog( @"received URL %@", url );
    // TODO: handle URL
}

@end
