//
//  PSMAquaTabStyle.h
//  PSMTabBarControl
//
//  Created by John Pannell on 2/17/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSMTabStyle.h"

@interface PSMAquaTabStyle : PSMTabStyleBase <PSMTabStyle> {
    NSImage *aquaTabBg;
    NSImage *aquaTabBgDown;
    NSImage *aquaTabBgDownGraphite;
    NSImage *aquaTabBgDownNonKey;
    NSImage *aquaDividerDown;
    NSImage *aquaDivider;
    
    NSDictionary *_objectCountStringAttributes;
	PSMTabBarControl *tabBar;
}

- (void)loadImages;
- (void)drawInteriorWithTabCell:(PSMTabBarCell *)cell inView:(NSView*)controlView;

- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
@end
