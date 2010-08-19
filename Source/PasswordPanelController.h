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


@class PasswordPanelController;
typedef void (^PasswordCompletionBlock)( BOOL accepted, PasswordPanelController *panel );

@interface PasswordPanelController : NSWindowController {
    NSString *user;
    NSString *password;
    BOOL save;
    
    IBOutlet NSObjectController *controller;
}

@property (readwrite, copy) NSString *user;
@property (readwrite, copy) NSString *password;
@property (readwrite, assign) BOOL save;
@property (readwrite, copy, nonatomic) NSURLCredential *credentials;

- (IBAction) acceptPassword: (id) sender;
- (IBAction) cancelPassword: (id) sender;

- (void) beginSheetModalForWindow: (NSWindow *) window completionBlock: (PasswordCompletionBlock) block;

@end
