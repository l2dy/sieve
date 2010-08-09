//
//  NSScanner+QuotedString.h
//  SaslTest
//
//  Created by Sven Weidauer on 09.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScanner (QuotedString) 
- (BOOL) scanQuotedString: (NSString **) outSTring;
@end
