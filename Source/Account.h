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


@interface Account : NSObject {
    NSURL *accountFileURL;
    NSString *accountName;
    NSString *host;
    NSString *user;
    BOOL tls;
    unsigned port;
    NSImage *icon;
}

@property (readwrite, copy) NSString *accountName;
@property (readwrite, copy) NSString *host;
@property (readwrite, copy) NSString *user;
@property (readwrite, assign) BOOL tls;
@property (readwrite, assign) unsigned port;
@property (readwrite, copy) NSImage *icon;
@property (readonly) NSURL *accountURL;

+ (Account *) readFromURL: (NSURL *) url;

- (BOOL) saveError: (NSError **) outError;

@end
