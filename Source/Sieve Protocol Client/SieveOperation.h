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

@class SieveClient;

@interface SieveOperation : NSObject {
@private
    __weak SieveClient *client;
    __weak void *userInfo;
    __weak id delegate;
}

@property (readwrite, assign) SieveClient *client;
@property (readwrite, assign) id delegate;
@property (readwrite, assign) void *userInfo;

- initForClient: (SieveClient *) newClient;
- initForClient: (SieveClient *) newClient delegate: (id) delegate userInfo: (void *) userInfo;

- (void) start;

- (void) receivedResponse: (NSDictionary *) response;
- (void) receivedSuccessResponse: (NSDictionary *) response;
- (void) receivedFailureResponse: (NSDictionary *) response;
- (NSString *) command;

@end


@interface SieveListScriptsOperation : SieveOperation
@end

@interface SieveGetScriptOperation : SieveOperation {
    NSString *scriptName;
}

@property (readwrite, copy) NSString *scriptName;

- initWithScript: (NSString *) script forClient: (SieveClient *) client delegate: (id) delegate userInfo: (void *) userInfo;

@end

@interface SieveDeleteScriptOperation : SieveOperation {
    NSString *scriptName;
}

@property (readwrite, copy) NSString *scriptName;

- initWithScript: (NSString *) script forClient: (SieveClient *) client delegate: (id) delegate userInfo: (void *) userInfo;


@end

@interface SieveSetActiveOperation : SieveOperation {
    NSString *scriptName;
}

@property (readwrite, copy) NSString *scriptName;

- initWithScript: (NSString *) script forClient: (SieveClient *) client delegate: (id) delegate userInfo: (void *) userInfo;

@end

@interface SievePutScriptOperation : SieveOperation {
    NSString *scriptName;
    NSData *script;
}

@property (readwrite, copy) NSString *scriptName;
@property (readwrite, copy) NSData *script;

- initWithScript: (NSString *) script name: (NSString *) name forClient: (SieveClient *) client delegate: (id) delegate userInfo: (void *) userInfo;

@end

@interface SieveRenameScriptOperation : SieveOperation {
    NSString *oldName;
    NSString *newName;
}

@property (readwrite, copy) NSString *oldName;
@property (readwrite, copy) NSString *newName;

- initWithOldName: (NSString *) from newName: (NSString *)to forClient: (SieveClient *) client delegate: (id) delegate userInfo: (void *) userInfo;

@end

