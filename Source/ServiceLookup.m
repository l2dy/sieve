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

#import "ServiceLookup.h"


@interface ServiceLookup ()
@property (readwrite, assign) BOOL timedOut;
@property (readwrite, copy) void (^block)();

- (void) notifyWithTimeout: (BOOL) isTimeOut;
- (void) callbackFiredWithRdata: (const void *)rdata length: (uint16_t)len more: (BOOL) moreComing;
@end

static inline unsigned rdata_priority( const void *rdata ) 
{
    uint16_t result = ((const uint16_t *)rdata)[0];
    return ntohs( result );
}

static inline unsigned rdata_weight( const void *rdata ) 
{
    uint16_t result = ((const uint16_t *)rdata)[1];
    return ntohs( result );
}

static inline unsigned rdata_port( const void *rdata ) 
{
    uint16_t result = ((const uint16_t *)rdata)[2];
    return ntohs( result );
}

static inline const char *rdata_name( const void *rdata, unsigned len )
{
    static char buffer[1024];
    const char *inStr = (const char *)rdata + 6;
    char *outStr = buffer;
    while (0 != *inStr) {
        unsigned span = *inStr++;
        memcpy( outStr, inStr, span );
        inStr += span;
        outStr += span;
        if (0 != *inStr) {
            *outStr++ = '.';
        }
        *outStr = 0;
    }
    return buffer;
}

@implementation ServiceLookup

@synthesize timeout;
@synthesize delegate;
@synthesize name;
@synthesize timedOut;
@synthesize block;

- initWithServiceName: (NSString *) serviceName;
{
    self = [super init];
    
    [self setName:  serviceName];
    [self setTimeout: 10.0];
    
    return self;
}

- (void) lookup;
{
    [self lookupWithBlock: nil];
}

static void ServiceLookupCallback(DNSServiceRef service, DNSServiceFlags flags, uint32_t interface, DNSServiceErrorType error,
                                  const char * fullname, uint16_t rrtype, uint16_t rrclass, uint16_t rdlen, const void * rdata, uint32_t ttl, void * context)
{
    ServiceLookup *l = context;
    [l callbackFiredWithRdata: rdata length: rdlen more: (flags & kDNSServiceFlagsMoreComing) == kDNSServiceFlagsMoreComing];
}

- (void) lookupWithBlock: (void (^)()) newBlock;
{
    [self setBlock:  newBlock];
    
    DNSServiceQueryRecord( &sdRef, 0, 0, [name cStringUsingEncoding: NSASCIIStringEncoding], kDNSServiceType_SRV, kDNSServiceClass_IN, ServiceLookupCallback, self );
    
    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, DNSServiceRefSockFD( sdRef ), 0, dispatch_get_main_queue() );
    dispatch_source_set_event_handler(source, ^ {
        DNSServiceProcessResult(sdRef);
    });
    dispatch_resume(source);
    
    timer = dispatch_source_create( DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue() );
    dispatch_source_set_timer( timer, dispatch_time( DISPATCH_TIME_NOW, timeout * NSEC_PER_SEC ), 0, (unsigned long long)NSEC_PER_SEC * 2 );
    dispatch_source_set_event_handler( timer, ^{
        [self notifyWithTimeout: YES];
        dispatch_release( timer ); timer = NULL;
        dispatch_release( source ); source = NULL;
    } );
    dispatch_resume( timer );
}

NSString * const kServiceLookupPriorityKey = @"priority";
NSString * const kServiceLookupWeightKey = @"weight";
NSString * const kServiceLookupPortKey = @"port";
NSString * const kServiceLookupHostKey = @"host";

- (void) callbackFiredWithRdata: (const void *)rdata length: (uint16_t)len more: (BOOL) moreComing;
{
    if (timer) {
        dispatch_release( timer );
        timer = NULL;
    }
    
    if (nil == result) {
        result = [[NSMutableArray alloc] initWithCapacity: 1];
    }
    
    NSNumber *priority = [NSNumber numberWithUnsignedInt: rdata_priority( rdata )];
    NSNumber *weight = [NSNumber numberWithUnsignedInt: rdata_weight( rdata )];
    NSNumber *port = [NSNumber numberWithUnsignedInt: rdata_port(  rdata )];
    NSString *host = [NSString stringWithCString: rdata_name( rdata, len ) encoding: NSASCIIStringEncoding];
    
    NSDictionary *entry = [NSDictionary dictionaryWithObjectsAndKeys: 
                           priority, kServiceLookupPriorityKey,
                           weight, kServiceLookupWeightKey,
                           port, kServiceLookupPortKey,
                           host, kServiceLookupHostKey,
                           nil];
    [result addObject: entry];
    
    if (!moreComing) {
        dispatch_release(source);
        source = NULL;
        
        [self notifyWithTimeout: NO];
    }
}

- (void) notifyWithTimeout: (BOOL) isTimeOut;
{
    [self setTimedOut: isTimeOut];
    
    if (block) {
        block();
        [self setBlock: nil];
    }
    
    if (isTimeOut) [delegate serviceLookupTimedOut: self];
    else [delegate serviceLookupGotResults: self];
}

- (void) dealloc;
{
    [result release];
    
    [self setName: nil];
    [self setBlock: nil];
    
    if (timer) dispatch_release(  timer  );
    if (source) dispatch_release( source );
    DNSServiceRefDeallocate( sdRef );
    
    [super dealloc];
}

- (NSArray *) result;
{
    return [[result copy] autorelease];
}

@end
