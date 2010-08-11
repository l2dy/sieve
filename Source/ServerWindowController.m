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
#import "SieveScriptViewController.h"

#import "PSMTabBarControl.h"

@implementation ServerWindowController

@synthesize scriptViewController;

- (id) init;
{
    if (nil == [super initWithWindowNibName: @"ServerWindow"]) return nil;
    
    
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

- (NSView *) documentView;
{
    if (nil == scriptViewController) {
        [self setScriptViewController: [[[SieveScriptViewController alloc] init] autorelease]];
    }
    return [scriptViewController view];
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
#pragma mark Handling documents

- (NSTabViewItem *) tabViewItemForDocument: (NSDocument *) document;
{
    if (nil == tabView) return nil;
    
    NSInteger index = [tabView indexOfTabViewItemWithIdentifier: document];
    NSTabViewItem *item = nil;
    if (index == NSNotFound) {
        item = [[[NSTabViewItem alloc] initWithIdentifier: document] autorelease];
        [item bind: @"label" toObject: document withKeyPath: @"displayName" options: nil];
        [item setView: [self documentView]];
        [tabView addTabViewItem: item];
    } else {
        item = [tabView tabViewItemAtIndex: index];
    }
}

- (void) windowDidLoad;
{
    NSDocument *doc = [self document];
    if (nil != doc) {
        [self tabViewItemForDocument: doc];
        [scriptViewController setRepresentedObject: doc];
    }
}

- (void) setDocument:(NSDocument *)document;
{
    [super setDocument: document];
    
    if (nil != document) {
        [tabView selectTabViewItem: [self tabViewItemForDocument: document]];
    }
    
    [scriptViewController setRepresentedObject: document];
}



- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName;
{
    return [NSString stringWithFormat: @"Server - %@", displayName];
}

@end
