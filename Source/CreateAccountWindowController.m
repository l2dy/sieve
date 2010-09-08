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


#import "CreateAccountWindowController.h"
#import "ServiceLookup.h"

NSString * const kAppErrorDomain = @"AppErrorDomain";

@interface CreateAccountWindowController ()

- (void) beginChecks;
- (void) checkConnection;
- (void) savePreset;

@end

@implementation CreateAccountWindowController

@synthesize savePassword;
@synthesize serverName;
@synthesize email;
@synthesize password;
@synthesize userName;
@synthesize port;
@synthesize canInteract;

- (void) run;
{
    isSheet = NO;
    [self showWindow: self];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
}

- (void) runAsSheetForWindow: (NSWindow *)window;
{
    isSheet = YES;
    [NSApp beginSheet: [self window] modalForWindow: window modalDelegate: self didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: NULL];
}

- (void) closeSelf;
{
    if (isSheet) {
        [NSApp endSheet: [self window]];
    }
    [[self window] orderOut: self];
    isSheet = NO;
}

- init;
{
    self =  [super initWithWindowNibName: @"CreateAccountWindow"];
    
    savePassword = YES;
    port = 2000;
    canInteract = YES;
    
    return self;
}

- (id) initWithWindowNibName: (NSString *)windowNibName;
{
    NSAssert( NO, @"Cannot be created with -init this" );
    return nil;
}

- (IBAction) cancelClicked: (id) sender;
{
    [self closeSelf];
}

- (IBAction) continueClicked: (id) sender;
{
    if (showsAdvancedView) {
        [self savePreset];
    } else {
        [self beginChecks];
    }
}

- (IBAction) switchToAdvancedView: (id) sender;
{
    if (!showsAdvancedView) {
        [self setCanInteract:  YES];
        [advancedView setFrame: [simpleView frame]];
        [[[self window] contentView] replaceSubview: simpleView with: advancedView];
        showsAdvancedView = YES;
    }
}

- (BOOL) validateEmail: (NSString **)string error: (NSError **)error;
{
    NSString *str = [*string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSRange range = [str rangeOfString:  @"@"];
    if (range.location == NSNotFound || range.location == [str length] - 1) {
        NSParameterAssert( NULL != error );
        NSString *message = [NSString stringWithFormat: NSLocalizedString( @"'%@' is not a valid e-mail address", @"Error for invalid e-mail address" ), str];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: message, NSLocalizedDescriptionKey, nil];
        
        *error = [NSError errorWithDomain: kAppErrorDomain code: kInvalidEmail userInfo: userInfo];
        return NO;
    } else {
        *string = str;
        return YES;
    }
}

- (void) beginChecks;
{
    if (showsAdvancedView) {
        return;
    }
    
    [self setCanInteract: NO];
 
    NSRange range = [email rangeOfString: @"@"];
    NSAssert( range.location != NSNotFound, @"Validation means there has to be a @" );
    
    [self setUserName: [email substringToIndex: range.location]];
    [self setServerName: [email substringFromIndex: range.location + 1]];
    
    [spinner setHidden:  NO];
    [spinner startAnimation: self];
    
    [statusText setHidden: NO];
    [statusText setStringValue: NSLocalizedString( @"Looking up host name", @"" )];
    
    ServiceLookup *lookup = [[ServiceLookup alloc] initWithServiceName: [NSString stringWithFormat: @"_sieve._tcp.%@", serverName]];
    [lookup setTimeout: [[NSUserDefaults standardUserDefaults] floatForKey: @"srvLookupTimeout"]];
    
    [lookup lookupWithBlock: ^{
        if (![lookup timedOut]) {
            NSArray *result = [lookup result];
            
            // TODO: figure out, which has the highest priority/weight
            NSDictionary *item = [result objectAtIndex: 0];
            [self setServerName: [item valueForKey: kServiceLookupHostKey]];
            [self setPort:  [[item valueForKey: kServiceLookupPortKey] unsignedIntValue]];
        }
        [self checkConnection];
        [lookup release];
    }];
}

- (void) checkConnection;
{
    [statusText setStringValue: NSLocalizedString( @"Trying to connect", @"" )];
    SieveClient *client = [[SieveClient alloc] init];
    [client setDelegate: self];
    
    [client connectToHost: serverName port: port];
}


- (void) savePreset;
{
    // TODO: save preset/bookmark
    [self closeSelf];
}

#pragma mark -
#pragma mark SieveClientDelegate

- (void) sieveClient: (SieveClient *) client needsCredentials: (NSURLCredential *) defaultCreds;
{
    // TODO: also try the email address as user name
    if (triedAuth) {
        [client cancelAuth];
        [client release];
        [self switchToAdvancedView: self];
    } else {
        NSURLCredential *creds = [NSURLCredential credentialWithUser: userName password: password persistence: NSURLCredentialPersistenceNone];
        triedAuth = YES;
        [client continueAuthWithCredentials: creds];
    }
}

- (void) sieveClientSucceededAuth: (SieveClient *) client;
{
    [client release];
    
    [self savePreset];
}

- (void) sieveClientEstablishedConnection: (SieveClient *) client;
{
    [statusText setStringValue: NSLocalizedString( @"Connected to server, trying to authenticate", @"" )];
}

// TODO: sieveClientCouldNotConnect: or something like that.

#pragma mark -

+ (void) initialize;
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys: 
                            [NSNumber numberWithFloat: 5.0], @"srvLookupTimeout",
                            nil]];
}

@end
