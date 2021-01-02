/* Copyright (c) 2010 Sven Weidauer
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
#import "SaveToServerPanelController.h"
#import "PasswordPanelController.h"
#import "ConnectionController.h"

#import "PSMTabBarControl.h"

@interface ServerWindowController ()

- (void) closeTab:(NSTabViewItem *)tab;

- (IBAction) doubleClickedScript: (id) sender;

@end

@implementation ServerWindowController

@synthesize client;
@synthesize baseURL;
@synthesize activeScript;

- (id) initWithURL: (NSURL *) url;
{
    if (nil == [super initWithWindowNibName: @"ServerWindow"]) return nil;
    
    [self setBaseURL: url];
    
    [self setClient: [[[SieveClient alloc] init] autorelease]];
    [client setDelegate: self];
    [client connectToURL: url];
    [client listScripts];
    
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
    [tabBar setAutomaticallyAnimates: YES];
    [tabBar setCanCloseOnlyTab: YES];
    
    [scriptListView setTarget: self];
    [scriptListView setDoubleAction: @selector( doubleClickedScript: )];
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
            [client getScript: [path lastPathComponent]];
        }
        [doc addWindowController: self];
    }
    [[self window] makeKeyAndOrderFront: self];
}

- (IBAction) doubleClickedScript: (id) sender;
{
    NSInteger row = [scriptListView clickedRow];
    if (row != -1) {
        NSString *scriptName = [[self objectInScriptsAtIndex: row] valueForKey: @"name"];
        [self openURL: [baseURL URLByAppendingPathComponent: scriptName]];
    }
}

- (IBAction) newDocument: (id) sender;
{
    NSDocument *doc = [[[ServerScriptDocument alloc] initWithServer: self URL: nil] autorelease];
    [[NSDocumentController sharedDocumentController] addDocument: doc];
    [doc addWindowController: self];
}

- (id) selectedScriptForSender: (id) sender;
{
    if ([sender isKindOfClass: [NSMenuItem class]]) {
        NSInteger clickedRow = [scriptListView clickedRow];
        if (clickedRow != -1) return [self objectInScriptsAtIndex: clickedRow];
    } else {
        NSArray *selectedObjects = [scriptsArrayController selectedObjects];
        if ([selectedObjects count] >= 1) return [selectedObjects objectAtIndex: 0];
    }
    return nil;
}

- (IBAction) activateScript: (id) sender;
{
    id selectedScript = [self selectedScriptForSender: sender];
    NSAssert( nil != selectedScript, @"User interface item enabled when it should not be" );
    
    [client setActiveScript: [selectedScript valueForKey: @"name"]];
}

- (IBAction) renameScript: (id) sender;
{
    id selectedScript = [self selectedScriptForSender: sender];
    NSAssert( nil != selectedScript, @"User interface item enabled when it should not be" );
    
    SaveToServerPanelController *savePanel = [[SaveToServerPanelController alloc] init];
    [savePanel beginSheetModalForWindow: [self window] completionBlock: ^( NSInteger rc, NSString *name ) {
        if (NSModalResponseOK == rc) {
            [client renameScript: [selectedScript valueForKey: @"name"] to: name];
        } 
        [savePanel release];
    }];
}

- (IBAction) delete: (id) sender;
{
    id selectedScript = [self selectedScriptForSender: sender];
    NSAssert( nil != selectedScript, @"User interface item enabled when it should not be" );

    [client deleteScript: [selectedScript valueForKey: @"name"]];
}

- (BOOL) validateUserInterfaceItem: (id <NSValidatedUserInterfaceItem>) item;
{
    id script = [self selectedScriptForSender: item];
    SEL action = [item action];
    if (action == @selector( delete: ) || action == @selector( activateScript: )) {
        if (nil == script) return NO;
        return ![[script valueForKey: @"active"] boolValue];
    } else if (action == @selector( renameScript: )) {
        return nil != script;
    } else return YES;
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

- (BOOL) tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem;
{
    NSLog( @"should close tab view for %@", [[[tabViewItem identifier] fileURL] absoluteString] );
    if ([[tabViewItem identifier] isDocumentEdited]) {
        [self closeTab: tabViewItem];
        return NO;
    } else {
        return YES;
    }
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

- (unsigned) countOfUnsavedDocuments;
{
    unsigned count = 0;
    for (NSTabViewItem *item in [tabView tabViewItems]) {
        if ([[item identifier] isDocumentEdited]) ++count;
    }
    return count;    
}

- (void) reallyCloseAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    NSParameterAssert( nil != contextInfo );
    void (^block)( BOOL ) = contextInfo;
    
    block( returnCode != NSModalResponseOK );
    [block release];
}

- (void) windowWillClose:(NSNotification *)notification;
{
    NSArray *items = [[tabView tabViewItems] copy];
    for (NSTabViewItem *item in items) {
        NSDocument *doc = [item identifier];
        [doc close];
        [tabView removeTabViewItem: item];
    }
    [items release];
    [[ConnectionController sharedConnectionController] closeConnection: self];
}

- (void) windowShouldCloseWithBlock: (void (^)( BOOL shouldClose )) shouldCloseBlock;
{
    unsigned unsavedDocuments = [self countOfUnsavedDocuments];
    if (0 == unsavedDocuments) {
        shouldCloseBlock( YES );
        
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText: @"There are unsaved scripts" defaultButton: @"Cancel" alternateButton:@"Close anyways" 
                                           otherButton: nil 
                             informativeTextWithFormat: @"There are %d unsaved documents. Do you really want to close them?", unsavedDocuments ];
        
        [alert beginSheetModalForWindow:[self window] modalDelegate:self 
                         didEndSelector:@selector(reallyCloseAlertDidEnd:returnCode:contextInfo:) contextInfo: [shouldCloseBlock copy]];
    }
}

- (BOOL) windowShouldClose:(id)sender;
{
    [self windowShouldCloseWithBlock: ^( BOOL shouldClose ) {
        if (shouldClose) [self close];
    }];
    
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
    if (nil != [baseURL port] && kSieveDefaultPort != [[baseURL port] intValue]) result = [result stringByAppendingFormat: @":%@", [baseURL port]];
    return result;
}

- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName;
{
    return [NSString stringWithFormat: @"%@ - %@", [self windowTitle], displayName];
}

#pragma mark -
#pragma mark Closing the window/tabs

- (void)document:(NSDocument *)document shouldClose:(BOOL)shouldClose  contextInfo:(void  *)contextInfo
{
    NSTabViewItem *tab = (NSTabViewItem *)contextInfo;
    if (shouldClose) {
        [tabView removeTabViewItem: tab];
        [self tabView: tabView didCloseTabViewItem: tab];
    }
}

- (void) closeTab: (NSTabViewItem *) tab;
{
    NSParameterAssert( nil != tab );
    
    NSDocument *doc = [tab identifier];
    [doc canCloseDocumentWithDelegate: self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo: tab];
}

- (IBAction) performCloseTab: (id) sender;
{
    [self closeTab: [tabView selectedTabViewItem]];
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
    
    if ([menuItem action] == @selector( saveDocument: )) {
        return [self document] != nil;
    }
  
    return [self validateUserInterfaceItem: menuItem];
}

- (void) saveDocument: (id) sender;
{
    // Why is that neccessary here? The other Save... items don’t have and need that.
    [[self document] saveDocument: sender];
}

#pragma mark -
#pragma mark SieveClient Delegate

- (void) sieveClient: (SieveClient *) c needsCredentials: (NSURLCredential *) defaultCreds;
{
    PasswordPanelController *passwordPanel = [[PasswordPanelController alloc] init];
    [passwordPanel setCredentials: defaultCreds];
    [passwordPanel beginSheetModalForWindow: [self window] completionBlock: ^( BOOL ok, PasswordPanelController *x ) {
        if (ok) [c continueAuthWithCredentials: [passwordPanel credentials]];
        else [c cancelAuth];
    }];
}

- (void) sieveClient: (SieveClient *) client retrievedScriptList: (NSArray *) scriptList active: (NSString *)newActiveScript contextInfo: (void *)ci;
{
    [self setScripts: scriptList];
    [self setActiveScript: newActiveScript];
}

- (void) sieveClient: (SieveClient *) client retrievedScript: (NSString *) script withName: (NSString *) scriptName contextInfo: (void *) ci;
{
    NSURL *scriptURL = [[self baseURL] URLByAppendingPathComponent: scriptName];
    ServerScriptDocument *doc = [[NSDocumentController sharedDocumentController] documentForURL: scriptURL];
    [doc finnishedDownload: script];
}

- (void) sieveClient: (SieveClient *) client activatedScript: (NSString *) scriptName contextInfo: (void *) ci;
{
    [self setActiveScript: scriptName];
}

- (void) sieveClient: (SieveClient *) client renamedScript: (NSString *) oldName to: (NSString *)newName contextInfo: (void *) ci;
{
    NSUInteger oldIndex = [scripts indexOfObject: oldName];
    NSAssert( NSNotFound != oldIndex, @"Renamed script I don't know anything about." );

    NSIndexSet *indices = [NSIndexSet indexSetWithIndex: oldIndex];
    [self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indices forKey: @"scripts"];
    [scripts replaceObjectAtIndex: oldIndex withObject: newName];
    [self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indices forKey: @"scripts"];
    
    NSURL *oldURL = [baseURL URLByAppendingPathComponent: oldName];
    NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForURL: oldURL];
    if (nil != doc) {
        NSURL *newURL = [baseURL URLByAppendingPathComponent: newName];
        [doc setFileURL: newURL];
    }
}

- (void) sieveClient: (SieveClient *) client deletedScript: (NSString *) scriptName contextInfo: (void *)ci;
{
    NSUInteger oldIndex = [scripts indexOfObject: scriptName];
    NSAssert( NSNotFound != oldIndex, @"Renamed script I don't know anything about." );
    
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex: oldIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indices forKey: @"scripts"];
    [scripts removeObjectAtIndex: oldIndex];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indices forKey: @"scripts"];
    
    NSURL *URL = [baseURL URLByAppendingPathComponent: scriptName];
    NSDocument *doc = [[NSDocumentController sharedDocumentController] documentForURL: URL];
    if (nil != doc) {
        [doc updateChangeCount: NSChangeDone];
    }
}

- (void) sieveClient: (SieveClient *) client savedScript: (NSString *) name contextInfo: (void *)ci;
{
    if (nil == scripts) scripts = [[NSMutableArray alloc] init];
    NSUInteger oldIndex = [scripts indexOfObject: name];
    if (NSNotFound == oldIndex) {
        NSIndexSet *indices = [NSIndexSet indexSetWithIndex: [scripts count]];
        [self willChange: NSKeyValueChangeInsertion valuesAtIndexes:indices forKey: @"scripts"];
        [scripts addObject: name];
        [self didChange: NSKeyValueChangeInsertion valuesAtIndexes:indices forKey: @"scripts"];
    }
}

#pragma mark -
#pragma mark Accessors

- (void) setScripts: (NSArray *) newScripts;
{
    if (scripts != newScripts) {
        [scripts release];
        scripts = [newScripts mutableCopy];
    }
}

- (unsigned)countOfScripts {
    if (!scripts) {
        scripts = [[NSMutableArray alloc] init];
    }
    return [scripts count];
}

- (id)objectInScriptsAtIndex:(unsigned)theIndex {
    if (!scripts) {
        scripts = [[NSMutableArray alloc] init];
    }
    NSString *name = [scripts objectAtIndex:theIndex];
    NSNumber *active = [NSNumber numberWithBool: [name isEqualToString: activeScript]];
    return [NSDictionary dictionaryWithObjectsAndKeys: name, @"name", active, @"active", nil];
}

+ (NSSet *) keyPathsForValuesAffectingScripts;
{
    return [NSSet setWithObject: @"activeScript"];
}

@end
