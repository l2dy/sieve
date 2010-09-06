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

#import <Cocoa/Cocoa.h>

#import "SieveClient.h"

extern NSString * const kAppErrorDomain;
enum {
    kInvalidEmail = 1,
};

@interface CreateAccountWindowController : NSWindowController < SieveClientDelegate > {
    IBOutlet NSView *simpleView;
    IBOutlet NSView *advancedView;
    BOOL showsAdvancedView;
    
    IBOutlet NSProgressIndicator *spinner;
    IBOutlet NSTextField *statusText;
    
    BOOL savePassword;
    NSString *email;
    NSString *password;
    NSString *userName;
    NSString *serverName;
    unsigned port;
    
    BOOL triedAuth;
    BOOL canInteract;
}

@property (assign, readwrite) BOOL savePassword;
@property (copy, readwrite) NSString *email;
@property (copy, readwrite) NSString *password;
@property (copy, readwrite) NSString *userName;
@property (copy, readwrite) NSString *serverName;
@property (assign, readwrite) unsigned port;

@property (assign, readwrite) BOOL canInteract;

- (IBAction) cancelClicked: (id) sender;
- (IBAction) continueClicked: (id) sender;
- (IBAction) switchToAdvancedView: (id) sender;

@end
