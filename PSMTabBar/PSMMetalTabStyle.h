//
//  PSMMetalTabStyle.h
//  PSMTabBarControl
//
//  Created by John Pannell on 2/17/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSMTabStyle.h"

@interface PSMMetalTabStyle : PSMTabStyleBase <PSMTabStyle> {
	
	NSDictionary *_objectCountStringAttributes;
	
	PSMTabBarOrientation orientation;
	PSMTabBarControl *tabBar;
}

- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;

@end
