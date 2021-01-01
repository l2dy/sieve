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

#import "Account.h"
#import "AccountList.h"

@interface Account ()

+ (NSImage *) defaultAccountIcon;
- initWithAccountFileURL: (NSURL *) url;

@property (copy, readwrite) NSURL *accountFileURL;
@property (assign, readwrite) BOOL dirty;
@property (assign, readwrite) BOOL changedAccountName;
@end


@implementation Account

@synthesize accountFileURL;
@synthesize accountName;
@synthesize host;
@synthesize user;
@synthesize tls;
@synthesize port;
@synthesize icon;
@synthesize dirty;
@synthesize changedAccountName;

+ (NSImage *) defaultAccountIcon;
{
    static NSImage *icon = nil;
    
    @synchronized( self ) {
        if (nil == icon) {
            icon = [NSImage imageNamed: @"NSNetwork"];
            [icon setSize: NSMakeSize( 16, 16 )];
            [icon retain];
        }
    }
    
    return icon;
}

static NSString * const kHostKey = @"host";
static NSString * const kUserKey = @"user";
static NSString * const kTLSKey = @"tls";
static NSString * const kPortKey = @"port";

- init;
{
    self = [super init];
    if (nil == self) {
        return nil;
    }
    
    port = 2000;
    tls = YES;
    
    return self;
}

- (BOOL) loadError: (NSError **) outError;
{
    if (nil == accountFileURL) {
        if (NULL != outError) {
            // TODO: set *outError to a new error object
        }
        return NO;
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: accountFileURL];
    if (nil == dict) {
        return NO;
    }
    
    [self setHost: [dict objectForKey: kHostKey]];
    if (nil == host) {
        return NO;
    }
    
    [self setUser: [dict objectForKey: kUserKey]];
    
    NSNumber *tlsNumber = [dict objectForKey: kTLSKey];
    if (nil != tlsNumber) {
        [self setTls: [tlsNumber boolValue]];
    } else {
        [self setTls: YES];
    }
    
    NSNumber *portNumber = [dict objectForKey: kPortKey];
    if (nil != portNumber) {
        [self setPort: [portNumber unsignedIntValue]];        
    } else {
        [self setPort: 2000];
    }
    
    NSString *name = nil;
    if (![accountFileURL getResourceValue: &name forKey: NSURLLocalizedNameKey error: NULL] || nil == name) {
        name = [[accountFileURL lastPathComponent] stringByDeletingPathExtension];
    }
    [self setAccountName: name];
    
    NSImage *customFileIcon = nil;
    if ([accountFileURL getResourceValue: &customFileIcon forKey: NSURLCustomIconKey error: NULL] && nil != customFileIcon) {
        [self setIcon: customFileIcon];
    }    
    
    [self setDirty: NO];
    [self setChangedAccountName: NO];
    
    return YES;
}

- initWithAccountFileURL: (NSURL *) url;
{
    NSParameterAssert( url );
    
    self = [self init];
    if (nil == self) {
        return nil;
    }

    [self setAccountFileURL: url];

    if (![self loadError: NULL]) {
        [self release];
        return nil;
    }
    
    return self;
}

- (void) setTls: (BOOL)tls_;
{
    if (tls != tls_) {
        tls_ = YES;
        [self setDirty: YES];
    }
}

- (void) setHost: (NSString *)host_;
{
    if (host != host_) {
        [host release];
        host = [host_ copy];
        
        [self setDirty: YES];
    }
}

- (void) setPort: (unsigned)port_;
{
    if (port != port_) {
        port = port_;
        
        [self setDirty: YES];
    }
}

- (void) setUser: (NSString *)user_;
{
    if (user != user_) {
        [user release];
        user = [user_ copy];
        
        [self setDirty: YES];
    }
}

- (void) setAccountName: (NSString *)accountName_;
{
    if (accountName != accountName_) {
        [accountName release];
        accountName = [accountName_ copy];
        
        [self setDirty: YES];
        [self setChangedAccountName: YES];
    }
}

+ (Account *) readFromURL: (NSURL *) url;
{
    return [[[self alloc] initWithAccountFileURL: url] autorelease];
}

- (NSImage *) icon;
{
    if (nil == icon) return [[self class] defaultAccountIcon];
    else return icon;
}

- (BOOL) saveError: (NSError **) outError;
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: host, kHostKey, 
                          user != nil ? user : @"", kUserKey, 
                          [NSNumber numberWithBool: tls], kTLSKey,
                          [NSNumber numberWithUnsignedInt: port], kPortKey,
                          nil];
    

    NSError *error = nil;
    NSData *saveData = [NSPropertyListSerialization dataWithPropertyList: dict format: NSPropertyListXMLFormat_v1_0 
                                                                 options: 0 error: &error];
    if (nil == saveData) {
        if (NULL != outError) {
            *outError = error;   
        }
        return NO;
    }
    
    NSURL *saveURL = accountFileURL;
    if (changedAccountName && nil != saveURL) {
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtURL: saveURL error: NULL];
        saveURL = nil;
    }
    
    if (nil == saveURL) {
        NSString *fileName = accountName;
        NSURL *accountsFolder = [[AccountList sharedAccountList] accountsFolder];
        saveURL = [accountsFolder URLByAppendingPathComponent: [fileName stringByAppendingPathExtension: @"sieveAccount"]];
     
        int try = 1;
        NSFileManager *fm = [NSFileManager defaultManager];
        while ([fm fileExistsAtPath: [saveURL path]]) {
            fileName = [NSString stringWithFormat: @"%@ (%d)", accountName, try];
            saveURL = [accountsFolder URLByAppendingPathComponent: [fileName stringByAppendingPathExtension: @"sieveAccount"]];
            ++try;
        }
        
        [self setAccountName: fileName];
    }
    
    if (![saveData writeToURL: saveURL options: 0 error: &error]) {
        if (NULL != outError) {
            *outError = error;
        }
        return NO;
    }
    
    [self setAccountFileURL: saveURL];
    [saveURL setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLHasHiddenExtensionKey error: NULL];
    
    [self setDirty: NO];
    [self setChangedAccountName: NO];
    
    return YES;
}

- (BOOL) deletePresetFileError: (NSError **)outError;
{
    if (nil != accountFileURL) {
        NSFileManager *fm = [NSFileManager defaultManager];
        return [fm removeItemAtURL: accountFileURL error: outError];
    } else {
        return YES;
    }
}

- (NSURL *) accountURL;
{
    NSString *hostPart = host;
    if (nil != user && ![user isEqualToString: @""]) {
        hostPart = [user stringByAppendingFormat: @"@%@", host];
    }
    if (2000 != port) {
        hostPart = [hostPart stringByAppendingFormat: @":%u", port];
    }
    return [NSURL URLWithString: [NSString stringWithFormat: @"sieve://%@/", hostPart]];
}

+ (NSSet *) keyPathsForValuesAffectingAccountURL;
{
    return [NSSet setWithObjects: @"host", @"user", @"port", nil];
}

- (NSAttributedString *) displayString;
{
    static NSDictionary *attributes = nil;
    if (nil == attributes) {
        attributes = [[NSDictionary dictionaryWithObjectsAndKeys: 
                       [NSFont systemFontOfSize: [NSFont systemFontSizeForControlSize: NSSmallControlSize]], NSFontAttributeName,
                       [NSColor lightGrayColor], NSForegroundColorAttributeName,
                       nil] retain];
    }
    
    NSMutableAttributedString *result = [[[NSMutableAttributedString alloc] initWithString: accountName] autorelease];
    NSString *urlString = [@"\n" stringByAppendingString: [[self accountURL] absoluteString]];
    NSAttributedString *subtitleString = [[[NSAttributedString alloc] initWithString: urlString attributes: attributes] autorelease];
    [result appendAttributedString: subtitleString];

    return result;
}

+ (NSSet *) keyPathsForValuesAffectingDisplayString;
{
    return [NSSet setWithObjects: @"accountURL", @"accountName", nil];
}

@end
