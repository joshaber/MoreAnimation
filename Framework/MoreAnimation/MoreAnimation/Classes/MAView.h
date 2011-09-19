//
//  MAView.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
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
