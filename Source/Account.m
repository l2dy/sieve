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

#import "Account.h"
#import "AccountList.h"

@interface Account ()

+ (NSImage *) defaultAccountIcon;
- initWithAccountFileURL: (NSURL *) url;

@property (copy, readwrite) NSURL *accountFileURL;

@end


@implementation Account

@synthesize accountFileURL;
@synthesize accountName;
@synthesize host;
@synthesize user;
@synthesize tls;
@synthesize port;
@synthesize icon;

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

- initWithAccountFileURL: (NSURL *) url;
{
    self = [self init];
    if (nil == self) {
        return nil;
    }

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: url];
    if (nil == dict) {
        [self release];
        return nil;
    }

    [self setAccountFileURL: url];
    
    [self setHost: [dict objectForKey: kHostKey]];
    if (nil == host) {
        [self release];
        return nil;
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
    if (![url getResourceValue: &name forKey: NSURLLocalizedNameKey error: NULL] || nil == name) {
        name = [[url lastPathComponent] stringByDeletingPathExtension];
    }
    [self setAccountName: name];
    
    NSImage *customFileIcon = nil;
    if ([url getResourceValue: &customFileIcon forKey: NSURLCustomIconKey error: NULL] && nil != customFileIcon) {
        [self setIcon: customFileIcon];
    }    
    
    return self;
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
    if (nil == saveURL) {
        NSString *fileName = accountName;
        NSURL *accountsFolder = [[AccountList sharedAccountList] accountsFolder];
        saveURL = [accountsFolder URLByAppendingPathComponent: [fileName stringByAppendingPathExtension: @"sieveAccount"]];
     
        int try = 1;
        NSFileManager *fm = [NSFileManager defaultManager];
        while ([fm fileExistsAtPath: [saveURL path]]) {
            fileName = [NSString stringWithFormat: @"%@ (%d).sieveAccount", accountName, try];
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
    
    return YES;
}

- (NSURL *) accountURL;
{
    NSString *hostPart = host;
    if (nil != user && ![user isEqualToString: @""]) {
        hostPart = [user stringByAppendingFormat: @"@%@", host];
    }
    return [NSURL URLWithString: [NSString stringWithFormat: @"sieve://%@:%u/", hostPart, port]];
}

@end
