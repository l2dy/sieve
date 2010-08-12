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


#import "ServerWindowController.h"
#import "ServerScriptDocument.h"

#import "PSMTabBarControl.h"

@implementation ServerWindowController

@synthesize baseURL;

- (id) initWithURL: (NSURL *) url;
{
    if (nil == [super initWithWindowNibName: @"ServerWindow"]) return nil;
    
    [self setBaseURL: url];
    
    return self;
}

- (id) initWithWindowNibName:(NSString *)windowNibName;
{
    NSAssert( NO, @"Should not be called" );
    return nil;
}

- (void) awakeFromNib;
{
    [tabBar setStyleNamed: @"Unified"];
    [tabBar setTearOffStyle: PSMTabBarTearOffMiniwindow];
    [tabBar setAllowsBackgroundTabClosing: YES];
    [tabBar setUseOverflowMenu: YES];
    [tabBar setAllowsBackgroundTabClosing: YES];
    [tabBar setAutomaticallyAnimates: YES];
}

- (void) openURL: (NSURL *) url;
{
    NSString *path = [url path];
    if ([path length] != 0 && ![path isEqualToString: @"/"]) {
        NSURL *documentURL = [baseURL URLByAppendingPathComponent: [path lastPathComponent]];
        ServerScriptDocument *doc = [[NSDocumentController sharedDocumentController] documentForURL: documentURL];
        if (nil == doc) {
            doc = [[[ServerScriptDocument alloc] initWithServer: self URL: documentURL] autorelease];
            [[NSDocumentController sharedDocumentController] addDocument: doc];
            [doc beginDownload];
        }
        [doc addWindowController: self];
    }
    [[self window] makeKeyAndOrderFront: self];
}

#pragma mark -
#pragma mark Tab bar delegate

- (BOOL)tabView:(NSTabView*)aTabView shouldDragTabViewItem:(NSTabViewItem *)tabViewItem fromTabBar:(PSMTabBarControl *)tabBarControl
{
    return [aTabView numberOfTabViewItems] > 1;
}

- (BOOL)tabView:(NSTabView*)aTabView shouldDropTabViewItem:(NSTabViewItem *)tabViewItem inTabBar:(PSMTabBarControl *)tabBarControl
{
	return YES;
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem;
{
    [tabViewItem unbind: @"label"];
    [[tabViewItem identifier] close];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[tabViewItem identifier] addWindowController: self];
}

#pragma mark -
#pragma mark NSWindow delegate

- (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard *)pasteboard
{
    return NO;
}


- (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu
{
    return NO;
}

#pragma mark -
#pragma mark Handling documents

- (NSTabViewItem *) tabViewItemForDocument: (SieveDocument *) document;
{
    if (nil == tabView) return nil;
    
    NSInteger index = [tabView indexOfTabViewItemWithIdentifier: document];
    NSTabViewItem *item = nil;
    if (index == NSNotFound) {
        item = [[[NSTabViewItem alloc] initWithIdentifier: document] autorelease];
        [item bind: @"label" toObject: document withKeyPath: @"displayName" options: nil];
        [item setView: [[document viewController] view]];
        [tabView addTabViewItem: item];
    } else {
        item = [tabView tabViewItemAtIndex: index];
    }
    
    return item;
}

- (void) windowDidLoad;
{
    SieveDocument *doc = [self document];
    if (nil != doc) {
        [self tabViewItemForDocument: doc];
    }
}

- (void) setDocument:(SieveDocument *)document;
{
    [super setDocument: document];
    
    if (nil != document) {
        [tabView selectTabViewItem: [self tabViewItemForDocument: document]];
    }
}

- (NSString *) windowTitle;
{
    NSString *result = [baseURL host];
    if (nil != [baseURL port] && 2000 != [[baseURL port] intValue]) result = [result stringByAppendingFormat: @":%@", [baseURL port]];
    return result;
}

- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName;
{
    return [NSString stringWithFormat: @"%@ - %@", [self windowTitle], displayName];
}

#pragma mark -
#pragma mark Closing the window/tabs

- (IBAction) performCloseTab: (id) sender;
{
    
}

- (BOOL) hasOpenTabs;
{
    return [tabView numberOfTabViewItems] > 0;
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem;
{
    if ([menuItem action] == @selector( performCloseTab: )) {
        return [self hasOpenTabs];
    }
}

@end
