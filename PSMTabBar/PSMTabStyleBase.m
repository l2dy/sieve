//
//  PSMTabStyleBase.m
//  Sieve
//
//  Created by Sven Weidauer on 31.08.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PSMTabStyle.h"

@implementation PSMTabStyleBase

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder 
{
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject:closeButton forKey:@"closeButton"];
        [aCoder encodeObject:closeButtonDown forKey:@"closeButtonDown"];
        [aCoder encodeObject:closeButtonOver forKey:@"closeButtonOver"];
        [aCoder encodeObject:closeDirtyButton forKey:@"closeDirtyButton"];
        [aCoder encodeObject:closeDirtyButtonDown forKey:@"closeDirtyButtonDown"];
        [aCoder encodeObject:closeDirtyButtonOver forKey:@"closeDirtyButtonOver"];
        [aCoder encodeObject:addTabButton forKey:@"addTabButton"];
        [aCoder encodeObject:addTabButtonDown forKey:@"addTabButtonDown"];
        [aCoder encodeObject:addTabButtonOver forKey:@"addTabButtonOver"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
    if (nil == [super init]) return nil;
    if ([aDecoder allowsKeyedCoding]) {
        closeButton = [[aDecoder decodeObjectForKey:@"closeButton"] retain];
        closeButtonDown = [[aDecoder decodeObjectForKey:@"closeButtonDown"] retain];
        closeButtonOver = [[aDecoder decodeObjectForKey:@"closeButtonOver"] retain];
        closeDirtyButton = [[aDecoder decodeObjectForKey:@"closeDirtyButton"] retain];
        closeDirtyButtonDown = [[aDecoder decodeObjectForKey:@"closeDirtyButtonDown"] retain];
        closeDirtyButtonOver = [[aDecoder decodeObjectForKey:@"closeDirtyButtonOver"] retain];
        addTabButton = [[aDecoder decodeObjectForKey:@"addTabButton"] retain];
        addTabButtonDown = [[aDecoder decodeObjectForKey:@"addTabButtonDown"] retain];
        addTabButtonOver = [[aDecoder decodeObjectForKey:@"addTabButtonOver"] retain];
    }
    return self;
}

- (void)dealloc
{
    [closeButton release];
    [closeButtonDown release];
    [closeButtonOver release];
    [closeDirtyButton release];
    [closeDirtyButtonDown release];
    [closeDirtyButtonOver release]; 
    [addTabButton release];
    [addTabButtonDown release];
    [addTabButtonOver release];
    
    [super dealloc];
}

- (NSImage *) closeButtonImageForCell: (PSMTabBarCell *) cell  
{
    NSImage *closeButtonImage = [cell isEdited] ? closeDirtyButton : closeButton;
    if ([cell closeButtonOver]) closeButtonImage = [cell isEdited] ? closeDirtyButtonOver : closeButtonOver;
    if ([cell closeButtonPressed]) closeButtonImage = [cell isEdited] ? closeDirtyButtonDown : closeButtonDown;
    return closeButtonImage;
}

@end

