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

#import "AccountList.h"
#import "Account.h"
#import "ConnectionController.h"
#import "CreateAccountWindowController.h"

NSString * const kAccountsFolderDefaultsKey = @"accountsFolder";

@interface AccountList ()

@property (readwrite, copy) NSURL *accountsFolder;
@property (readwrite, copy, nonatomic) NSString *observedPath;

- (void) scanAccountsDirectory;

@end


@implementation AccountList

@synthesize accountsFolder;
@synthesize observedPath;

+ (void) initialize;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSApplicationSupportDirectory, NSUserDomainMask, NO );
    if ([paths count] >= 1) {
        NSString *supportDirectory = [[paths objectAtIndex: 0] stringByAppendingPathComponent: [[NSBundle mainBundle] bundleIdentifier]];
        NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys: [supportDirectory stringByAppendingPathComponent: @"Accounts"], kAccountsFolderDefaultsKey, nil];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    }
}

+ (NSURL *) accountsFolder;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *result = [[defaults URLForKey: kAccountsFolderDefaultsKey] fileReferenceURL];

    NSString *path = [result path];
    if (nil == path) {
        path = [[[defaults volatileDomainForName: NSRegistrationDomain] objectForKey: kAccountsFolderDefaultsKey] stringByExpandingTildeInPath];
    }

    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath: path]) {
        NSError *outError = nil;
        if (![fm createDirectoryAtPath: path withIntermediateDirectories: YES attributes: nil error: &outError]) {
            NSAlert *alert = [NSAlert alertWithError: outError];
            [alert runModal];
            return nil;
        }
        
        result = [[NSURL fileURLWithPath: path isDirectory: YES] fileReferenceURL];
        [defaults setURL: result forKey: kAccountsFolderDefaultsKey];
    }
    
    return result;
}

static AccountList *sharedAccountList = nil;

+ (AccountList *) sharedAccountList;
{
    @synchronized (self) {
        if (nil == sharedAccountList) {
            [[self alloc] init];
        }
        return sharedAccountList;
    }
}

- init;
{
    self = [super init];

    @synchronized ([self class]) {
        if (nil != sharedAccountList) {
            [self release];
            self = sharedAccountList;
        } else if (nil != self) {
            sharedAccountList = self;

            [self setAccountsFolder: [[self class] accountsFolder]];
        }
    }
  
    return self;
}

- (id) copyWithZone: (NSZone *) zone;
{
    return self;
}

- (id) retain;
{
    return self;
}

- (id) autorelease;
{
    return self;
}

- (void) release;
{
}

- (NSUInteger) retainCount;
{
    return NSUIntegerMax;
}

- (void) setAccountsFolder: (NSURL *) folder;
{
    if (accountsFolder != folder) {
        [accountsFolder release];
        accountsFolder = [folder copy];
        
        [self setObservedPath: [accountsFolder path]];
        
        if (nil != accountsFolder) {
            [[NSUserDefaults standardUserDefaults] setURL: [accountsFolder fileReferenceURL] forKey: kAccountsFolderDefaultsKey];
        }
    }
}

- (void) setObservedPath: (NSString *) newObservedPath;
{
    if (newObservedPath != observedPath) {
        if (nil != observedPath) {
            // TODO: stop observing observedPath
        }

        [observedPath release];
        observedPath = [newObservedPath copy];

        if (nil != observedPath) {
            // TODO: start observing observedPath
            [self scanAccountsDirectory];
        }
    }
}

NSString * const kAccountUTI = @"net.dergraf.sieve.sieve-account";

- (void) scanAccountsDirectory;
{
    NSDirectoryEnumerator *dir = [[NSFileManager defaultManager] enumeratorAtURL: accountsFolder 
                                                      includingPropertiesForKeys: [NSArray arrayWithObjects: NSURLLocalizedNameKey, NSURLTypeIdentifierKey, NSURLCustomIconKey, nil]
                                                                         options: NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles
                                                                    errorHandler: nil];
    NSMutableArray *allAccounts = [NSMutableArray array];
    for (NSURL *item in dir) {
        NSString *uti = nil;
        if (![item getResourceValue: &uti forKey: NSURLTypeIdentifierKey error: NULL]) {
            continue;
        }
        
        if (UTTypeEqual( (CFStringRef)uti, (CFStringRef)kAccountUTI )) {
            [allAccounts addObject: [Account readFromURL: item]];
        }
    }
    
    [self setAccounts: allAccounts];
}

- (NSArray *) accounts;
{
    return accounts;
}

- (void) setAccounts: (NSArray *) newAccounts;
{
    if (accounts != newAccounts) {
        [accounts release];
        accounts = [newAccounts mutableCopy];
        updateMenu = YES;
    }
}

- (IBAction) openAccount: (id) sender;
{
    NSURL *url = [[sender representedObject] accountURL];
    [[ConnectionController sharedConnectionController] openURL: url];
}

- (IBAction) createAccount: (id) sender;
{
    CreateAccountWindowController *wc = [[CreateAccountWindowController alloc] init];
    [wc run];
}

- (void) addAccount: (Account *) newAccount;
{
    [self insertObject: newAccount inAccountsAtIndex: [accounts count]];
}

#pragma mark -
#pragma mark NSMenuDelegate

enum {
    kDefaultTag = 0,
    kSeparatorTag = 1,
    kBookmarkTag,
};

- (void) menuNeedsUpdate: (NSMenu *)menu;
{
    if (updateMenu) {
        updateMenu = NO;
        
        NSMenuItem *separator = [menu itemWithTag: kSeparatorTag];
        if (nil == separator && [accounts count] > 0) {
            separator = [NSMenuItem separatorItem];
            [separator setTag: kSeparatorTag];
            [menu addItem: separator];
        }
        
        const NSInteger count = [menu numberOfItems];
        NSInteger firstItem = [menu indexOfItemWithTag: kBookmarkTag];
        if (-1 == firstItem) firstItem = count;
        
        for (Account *account in accounts) {
            NSMenuItem *item = nil;
            if (firstItem < count) {
                item = [menu itemAtIndex: firstItem];
            } else {
                item = [[[NSMenuItem alloc] initWithTitle: [account accountName] action: @selector(openAccount:) keyEquivalent: @""] autorelease];
                [item setTag: kBookmarkTag];
                [item setTarget: self];
                [item bind: @"title" toObject: item withKeyPath: @"representedObject.accountName" options: nil];
                [item bind: @"image" toObject: item withKeyPath: @"representedObject.icon" options: nil];
                [menu addItem: item];
            }
            [item setRepresentedObject: account];
            ++firstItem;
        }
        
        // Remove all extra menu items...
        for (int i = count - 1; i >= firstItem; --i) {
            NSLog( @"remove %d", i );
            [menu removeItemAtIndex: i];
        }
    }
}

- (unsigned)countOfAccounts 
{
    return [accounts count];
}

- (id)objectInAccountsAtIndex:(unsigned)theIndex {
    return [accounts objectAtIndex:theIndex];
}

- (void)getAccounts:(id *)objsPtr range:(NSRange)range {
    if (!accounts) {
        accounts = [[NSMutableArray alloc] init];
    }
    [accounts getObjects:objsPtr range:range];
}

- (void)insertObject:(id)obj inAccountsAtIndex:(unsigned)theIndex {
    if (!accounts) {
        accounts = [[NSMutableArray alloc] init];
    }
    [accounts insertObject:obj atIndex:theIndex];
    updateMenu = YES;
}

- (void)removeObjectFromAccountsAtIndex:(unsigned)theIndex {
    [accounts removeObjectAtIndex:theIndex];
    updateMenu = YES;
}

- (void)replaceObjectInAccountsAtIndex:(unsigned)theIndex withObject:(id)obj {
    if (!accounts) {
        accounts = [[NSMutableArray alloc] init];
    }
    [accounts replaceObjectAtIndex:theIndex withObject:obj];
    updateMenu = YES;
}

@end
