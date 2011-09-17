//
//  MAView.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MALayer;

/**
 * An \c NSView that displays an #MALayer hierarchy.
 */
@interface MAView : NSView
/**
 * The layer to display in the receiver.
 */
@property (nonatomic, strong) MALayer *contentLayer;
@end
