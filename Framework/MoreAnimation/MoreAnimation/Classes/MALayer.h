//
//  MALayer.h
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MALayer;

/**
 * The delegate for an #MALayer. Delegation can be used to provide custom layer
 * rendering without having to subclass #MALayer.
 */
@protocol MALayerDelegate <NSObject>
@optional
/**
 * Displays \a layer, caching its rendering in the layer's MALayer#contents
 * property.
 *
 * If implemented, this method is invoked instead of MALayer#display.
 */
- (void)displayLayer:(MALayer *)layer;

/**
 * Draws \a layer into \a context.
 *
 * If implemented, this method is invoked instead of MALayer#drawInContext:.
 */
- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context;
@end

/**
 * A layer, which can have arbitrary content and any number of sublayers.
 */
@interface MALayer : NSObject
/**
 * The frame of the receiver (specified in the coordinate space of its
 * superlayer).
 */
@property (nonatomic, assign) CGRect frame;

/**
 * The bounds of the receiver (specified in the receiver's coordinate space).
 */
@property (nonatomic, readonly) CGRect bounds;

/**
 * If set, a delegate to use for certain rendering operations.
 */
@property (nonatomic, weak) id<MALayerDelegate> delegate;

/**
 * Whether the receiver has been marked as needing display.
 */
@property (nonatomic, readonly, assign) BOOL needsDisplay;

/**
 * The contents of the layer. Can be set to a \c CGImageRef to display. If not
 * explicitly set, the layer may store its own cached contents here in an
 * unspecified format (i.e., you cannot depend on this being a \c CGImageRef).
 */
@property (strong) id contents;

/**
 * The sublayers of the receiver.
 */
@property (nonatomic, readonly, strong) NSMutableArray *sublayers;

/**
 * The superlayer of the receiver, or \c nil if it has no superlayer.
 */
@property (nonatomic, readonly, weak) MALayer *superlayer;

/**
 * Invokes #drawInContext: with a custom rendering context, then caches the
 * drawn content in the #contents property.
 *
 * You should not call this method directly. Subclasses can override this method
 * to set the #contents property to an appropriate object.
 *
 * @sa MALayerDelegate#displayLayer:
 */
- (void)display;

/**
 * Redraws the layer if it has been marked as needing display.
 */
- (void)displayIfNeeded;

/**
 * Draws the receiver into \a context. The default implementation does nothing.
 *
 * This method does not draw sublayers.
 */
- (void)drawInContext:(CGContextRef)context;

/**
 * Renders the receiver and all of its sublayers into \a context.
 */
- (void)renderInContext:(CGContextRef)context;

/**
 * Marks the receiver as needing display.
 */
- (void)setNeedsDisplay;

/**
 * Adds \a layer as a sublayer of the receiver after removing it from its
 * current superlayer.
 */
- (void)addSublayer:(MALayer *)layer;

/**
 * Removes the receiver from its current #superlayer. If the receiver has no
 * #superlayer, nothing happens.
 */
- (void)removeFromSuperlayer;

@end
