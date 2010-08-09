//
//  NSScanner+QuotedString.m
//  SaslTest
//
//  Created by Sven Weidauer on 09.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSScanner+QuotedString.h"


@implementation  NSScanner (QuotedString)

- (BOOL) scanQuotedString: (NSString **) outString;
{
    if (![self scanString: @"\"" intoString: NULL]) return NO;
    
    NSString *result = @"";
    [self scanUpToString: @"\"" intoString: &result];
    
    [self scanString: @"\"" intoString: NULL];
    
    if (outString != NULL) *outString = result;
    
    return YES;
}

@end
