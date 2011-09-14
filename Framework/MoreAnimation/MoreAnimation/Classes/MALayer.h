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
 * The position of the layer relative to its superlayer, expressed in the
 * superlayer's coordinate system.
 */
@property (assign) CGPoint position;

/**
 * The Z component of the layer's #position.
 */
@property (assign) CGFloat zPosition;

/**
 * The location within the bounds of the layer that corresponds with the
 * #position coordinate. Specifies how the #bounds are positioned relative to
 * the #position property, as well as serving as the point that transforms are
 * applied around.
 */
@property (assign) CGPoint anchorPoint;

/**
 * The Z component of the layer's #anchorPoint.
 */
@property (assign) CGFloat anchorPointZ;

/**
 * The scale factor applied to the layer.
 */
@property (assign) CGFloat contentsScale;

/**
 * Convenience accessor to get and set the #transform as a \c CGAffineTransform.
 */
@property (assign) CGAffineTransform affineTransform;

/**
 * A transform to be applied to each sublayer before rendering.
 */
@property (assign) CATransform3D sublayerTransform;

/**
 * The frame of the receiver (specified in the coordinate space of its
 * superlayer).
 */
@property (assign) CGRect frame;

/**
 * The bounds of the receiver (specified in the receiver's coordinate space).
 */
@property (assign) CGRect bounds;

/**
 * A transformation to apply to this layer before drawing.
 */
@property (assign) CATransform3D transform;

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
 * Returns the affine transformation that would have to be applied to convert
 * from the receiver's coordinate system to that of \a layer.
 */
- (CGAffineTransform)affineTransformToLayer:(MALayer *)layer;

/**
 * Converts the given point, specified in the coordinate system of \a layer, to
 * that of the receiver.
 */
- (CGPoint)convertPoint:(CGPoint)point fromLayer:(MALayer *)layer;

/**
 * Converts the given point, specified in the coordinate system of the receiver,
 * to that of \a layer.
 */
- (CGPoint)convertPoint:(CGPoint)point toLayer:(MALayer *)layer;

/**
 * Converts the given rectangle, specified in the coordinate system of \a layer, to that of the receiver.
 */
- (CGRect)convertRect:(CGRect)rect fromLayer:(MALayer *)layer;

/**
 * Converts the given rectangle, specified in the coordinate system of the receiver, to that of \a layer.
 */
- (CGRect)convertRect:(CGRect)rect toLayer:(MALayer *)layer;

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

/**
 * Returns whether the receiver is a descendant of or identical to \a layer.
 */
- (BOOL)isDescendantOfLayer:(MALayer *)layer;

@end
