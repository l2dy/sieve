//
//  NSData+Base64Encoding.h
//  SaslTest
//
//  Created by Sven Weidauer on 08.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSData (Base64Encoding)

- (NSString *) base64EncodedString;

@end

@interface NSString (Base64Decoding) 

- (NSData *) base64DecodedData;

@end
