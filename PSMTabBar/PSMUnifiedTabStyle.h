//
//  PSMUnifiedTabStyle.h
//  --------------------
//
//  Created by Keith Blount on 30/04/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSMTabStyle.h"


@interface PSMUnifiedTabStyle : PSMTabStyleBase <PSMTabStyle>
{
    NSDictionary *_objectCountStringAttributes;
    
    CGFloat leftMargin;
	PSMTabBarControl *tabBar;
}

- (void)setLeftMarginForTabBarControl:(CGFloat)margin;

@end
