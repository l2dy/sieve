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
#import <dns_sd.h>

@class ServiceLookup;

@protocol ServiceLookupDelegate <NSObject> 

- (void) serviceLookupGotResults: (ServiceLookup *) sl;
- (void) serviceLookupTimedOut: (ServiceLookup *) sl;

@end

extern NSString * const kServiceLookupPriorityKey;  // = @"priority";
extern NSString * const kServiceLookupWeightKey;    // = @"weight";
extern NSString * const kServiceLookupPortKey;      // = @"port";
extern NSString * const kServiceLookupHostKey;      // = @"host";


@interface ServiceLookup : NSObject {
    NSString *name;
    NSMutableArray *result;
    
    DNSServiceRef sdRef;
    dispatch_source_t timer;
    dispatch_source_t source;
    
    NSTimeInterval timeout;
    BOOL timedOut;
    
    void (^block)();
    __weak id <ServiceLookupDelegate> delegate;
}

@property (readwrite, assign) NSTimeInterval timeout;
@property (readwrite, assign) id <ServiceLookupDelegate> delegate;
@property (readwrite, copy) NSString *name;
@property (readonly, retain) NSArray *result;
@property (readonly, assign) BOOL timedOut;

- initWithServiceName: (NSString *) serviceName;
- (void) lookupWithBlock: (void (^)())newBlock;
- (void) lookup;

@end
