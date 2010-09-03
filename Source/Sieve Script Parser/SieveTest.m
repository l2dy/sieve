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


#import "SieveTest.h"


@interface SieveTest ()

@property (readwrite,assign) BOOL inverted;
@property (readwrite,copy) NSString *name;
@property (readwrite,copy) NSArray *parameters;

@end

@implementation SieveTest

@synthesize inverted;
@synthesize name;
@synthesize parameters;

- (id) copyWithZone:(NSZone *)zone;
{
    return [[[self class] allocWithZone: zone] initWithName: name parameters:parameters];
}

- (SieveTest *) invertedTest;
{
    SieveTest *result = [self copy];
    [result setInverted: !inverted];
    return [result autorelease];
}

- initWithName: (NSString *) newName parameters: (NSArray *) newParameters;
{
    if (nil == [super init]) return nil;
    
    [self setName: newName];
    [self setParameters: newParameters];
    
    return self;
}


- (void) dealloc;
{
    [self setName: nil];
    [self setParameters: nil];
    
    [super dealloc];
}

@end


@implementation  SieveAllOfTest

- initWithChildren: (NSArray *) children;
{
    return [super initWithName: @"allof" parameters: children];
}

- initWithName: (NSString *) newName parameters: (NSArray *) newParameters;
{
    [NSException raise: @"InvalidInitializer" format: @"SieveAllOfTest cannot be initialized with a different name"];
}

- (id) copyWithZone:(NSZone *)zone;
{
    return [[[self class] allocWithZone: zone] initWithChildren: parameters];
}

@end

@implementation SieveAnyOfTest

- initWithChildren: (NSArray *) children;
{
    return [super initWithName: @"anyof" parameters: children];
}

- initWithName: (NSString *) newName parameters: (NSArray *) newParameters;
{
    [NSException raise: @"InvalidInitializer" format: @"SieveAnyOfTest cannot be initialized with a different name"];
}

- (id) copyWithZone:(NSZone *)zone;
{
    return [[[self class] allocWithZone: zone] initWithChildren: parameters];
}


@end

