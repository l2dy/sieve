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

#import "PSMTabBarControl.h"

@implementation ServerWindowController

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

@end
