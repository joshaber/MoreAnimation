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
 * Renders the receiver and all of its sublayers into \a context. If \a
 * allowCaching is \c NO, the receiver and its sublayers should not be cached in
 * any way (the most likely reason being that an ancestor is already performing
 * subtree caching).
 */
- (void)renderInContext:(CGContextRef)context allowCaching:(BOOL)allowCaching;

/**
 * Marks the receiver and its ancestors as needing re-rendering.
 */
- (void)setNeedsRender;
@end
