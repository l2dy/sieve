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


#import "SieveDocumentController.h"
#import "SieveDocument.h"

#import <objc/Object.h>



@implementation SieveDocumentController

- (void) closeAllDocumentsWithDelegate:(id)delegate didCloseAllSelector:(SEL)didCloseAllSelector contextInfo:(void *)contextInfo;
{
    if ([[self documents] count] > 0) {
        SieveDocument *lastDocument = [[self documents] lastObject];
        [lastDocument tryCloseWithBlock: ^( BOOL didClose ) {
            if (didClose) {
                [self closeAllDocumentsWithDelegate: delegate didCloseAllSelector:didCloseAllSelector contextInfo: contextInfo];
            } else {
                ((void (*)(id, SEL, id, BOOL, void *))objc_msgSend)( delegate, didCloseAllSelector, self, NO, contextInfo );
            }
        }];
    } else {
        ((void (*)(id, SEL, id, BOOL, void *))objc_msgSend)( delegate, didCloseAllSelector, self, YES, contextInfo );
    }
}

@end
