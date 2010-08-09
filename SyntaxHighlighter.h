//
//  SyntaxHighlighter.h
//  Sieve
//
//  Created by Sven Weidauer on 05.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SyntaxHighlighter : NSObject < NSTextStorageDelegate > {
    IBOutlet NSTextView *textView;
}

@end
