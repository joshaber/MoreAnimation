//
//  MALayer+Private.h
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Released into the public domain.
//

#import <AppKit/AppKit.h>

@interface MALayer (Private)
/**
 * Marks the receiver and its ancestors as needing re-rendering.
 */
- (void)setNeedsRender;
@end
