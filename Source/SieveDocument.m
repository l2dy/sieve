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


#import "SieveDocument.h"
#import "SieveScriptViewController.h"
#import "SieveDocumentWindowController.h"

NSString * const kSieveScriptFileType = @"SieveScript";


@interface NSDocument (MessingWithInternals)
- (id) _setDisplayName: (id) newName;
@end

@implementation SieveDocument

@synthesize script;
@synthesize viewController;

-(void) makeWindowControllers;
{
    [self addWindowController: [[[SieveDocumentWindowController alloc] init] autorelease]];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSAssert( [typeName isEqualToString: kSieveScriptFileType], @"Only supporting sieve scripts" );
    
	return [script dataUsingEncoding: NSUTF8StringEncoding];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSAssert( [typeName isEqualToString: kSieveScriptFileType], @"Only supporting sieve scripts" );

    [self setScript: [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease]];
    return YES;
}

- (NSViewController *) viewController;
{
    if (nil == viewController) {
        viewController = [[SieveScriptViewController alloc] init];
        [viewController setRepresentedObject: self];
    }
    return viewController;
}

- (void) setViewController: (NSViewController *) newViewController;
{
    if (viewController != newViewController) {
        [viewController release];
        viewController = [newViewController retain];
        [viewController setRepresentedObject: self];
    }
}

#pragma mark -
#pragma mark Hackery to support binding displayName
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString: @"displayName"]) return NO;
    else return [super automaticallyNotifiesObserversForKey: key];
}

- (id) _setDisplayName: (id) newName;
{
    [self willChangeValueForKey: @"displayName"];
    id r = [super _setDisplayName: newName];
    [self didChangeValueForKey: @"displayName"];
    return r;
}

@end
