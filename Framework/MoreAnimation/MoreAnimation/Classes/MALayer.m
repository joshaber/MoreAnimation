//
//  MALayer.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MALayer.h"
#import "MALayer+Private.h"
#import <libkern/OSAtomic.h>

@interface MALayer () {
	/**
	 * The contents of this layer. This may be any object type needed to render
	 * the layer efficiently, including a \c CGImageRef or \c CGLayerRef.
	 *
	 * Use \c CFGetTypeID() or an \c isKindOfClass: check to determine this
	 * object's type before attempting to use it.
	 */
	id m_contents;

	/**
	 * A dispatch queue used to serialize rendering operations that need to be
	 * performed in order.
	 */
	dispatch_queue_t m_renderQueue;
}

/**
 * The layer's #contents, if it is a \c CGImageRef, or \c NULL otherwise.
 */
@property (readonly) CGImageRef contentsImage;

/**
 * The layer's #contents, if it is a \c CGLayerRef, or \c NULL otherwise.
 */
@property (readonly) CGLayerRef contentsLayer;

/**
 * If the receiver and \a layer share a common parent (or one is the parent of
 * the other), this returns that parent layer. If the receiver and \a layer do
 * not exist in the same layer tree, \c nil is returned.
 */
- (MALayer *)commonParentLayerWithLayer:(MALayer *)layer;

/**
 * Returns the affine transformation needed to move into the coordinate system
 * of \a sublayer, which must be an immediate descendant of the receiver.
 */
- (CGAffineTransform)affineTransformToImmediateSublayer:(MALayer *)sublayer;

// publicly readonly
@property (nonatomic, readwrite, strong) NSMutableArray *sublayers;
@property (nonatomic, readwrite, weak) MALayer *superlayer;
@property (nonatomic, readwrite, assign) BOOL needsDisplay;
@end


@implementation MALayer

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if(self == nil) return nil;

	m_renderQueue = dispatch_queue_create("MoreAnimation.MALayer", DISPATCH_QUEUE_SERIAL);

	self.sublayers = [NSMutableArray array];
	self.anchorPoint = CGPointMake(0.5, 0.5);
	self.transform = CATransform3DIdentity;
	self.sublayerTransform = CATransform3DIdentity;

	// mark layers as needing display right off the bat, since no content has
	// yet been rendered
	self.needsDisplay = YES;

	return self;
}

- (void)dealloc {
	dispatch_release(m_renderQueue);
}

#pragma mark Properties

- (id)contents {
  	__block id image = NULL;

	// layer contents should only be read/written from a single thread at a time
	dispatch_sync(m_renderQueue, ^{
		image = m_contents;
	});

	return image;
}

- (CGImageRef)contentsImage {
  	CGImageRef obj = (__bridge CGImageRef)self.contents;
	if (!obj)
		return NULL;

	CFTypeID typeID = CFGetTypeID(obj);

	// return self.contents if it is a CGImageRef
	if (typeID == CGImageGetTypeID())
		return obj;
	else
		return NULL;
}

- (CGLayerRef)contentsLayer {
  	CGLayerRef obj = (__bridge CGLayerRef)self.contents;
	if (!obj)
		return NULL;

	CFTypeID typeID = CFGetTypeID(obj);

	// return self.contents if it is a CGLayerRef
	if (typeID == CGLayerGetTypeID())
		return obj;
	else
		return NULL;
}

- (void)setContents:(id)contents {
	// layer contents should only be read/written from a single thread at a time
	dispatch_async(m_renderQueue, ^{
		m_contents = contents;
	});
}

- (CGAffineTransform)affineTransform {
    return CATransform3DGetAffineTransform(self.transform);
}

- (void)setAffineTransform:(CGAffineTransform)affineTransform {
    self.transform = CATransform3DMakeAffineTransform(affineTransform);
}

- (CGRect)frame {
    CGSize size = self.bounds.size;
    CGPoint anchor = self.anchorPoint;
    CGPoint originalPosition = self.position;

    CGPoint transformedAnchorPoint = CGPointMake(
        (anchor.x - 0.5) * size.width,
        (anchor.y - 0.5) * size.height
    );

    CGPoint newPosition = CGPointMake(
        originalPosition.x - transformedAnchorPoint.x,
        originalPosition.y - transformedAnchorPoint.y
    );

    return CGRectMake(
        newPosition.x,
        newPosition.y,
        size.width,
        size.height
    );
}

- (void)setFrame:(CGRect)rect {
    CGSize size = rect.size;
    self.bounds = CGRectMake(0, 0, size.width, size.height);

    CGPoint anchor = self.anchorPoint;

    CGPoint transformedAnchorPoint = CGPointMake(
        (anchor.x - 0.5) * size.width,
        (anchor.y - 0.5) * size.height
    );

    self.position = CGPointMake(
        CGRectGetMidX(rect) - transformedAnchorPoint.x,
        CGRectGetMidY(rect) - transformedAnchorPoint.y
    );
}

@synthesize sublayers;
@synthesize superlayer;
@synthesize delegate;
@synthesize needsDisplay;
@synthesize position;
@synthesize zPosition;
@synthesize anchorPoint;
@synthesize anchorPointZ;
@synthesize contentsScale;
@synthesize sublayerTransform;
@synthesize bounds;
@synthesize transform;

#pragma mark Coordinate systems and transformations

- (CGAffineTransform)affineTransformToImmediateSublayer:(MALayer *)sublayer; {
    NSAssert(sublayer.superlayer == self, @"argument to -affineTransformToImmediateSublayer: must have the receiver as its superlayer");

    CGPoint layerAnchor = sublayer.anchorPoint;
    CGPoint layerPosition = sublayer.position;
    CGSize size = sublayer.bounds.size;

    // translate to anchor point of the sublayer
    CGAffineTransform affineTransform = CGAffineTransformMakeTranslation(
        layerPosition.x + ((layerAnchor.x - 0.5) * size.width),
        layerPosition.y + ((layerAnchor.y - 0.5) * size.height)
    );

    // apply the sublayer's affine affineTransform
    affineTransform = CGAffineTransformConcat(sublayer.affineTransform, affineTransform);

    // translate back to the origin in the sublayer's coordinate system
    affineTransform = CGAffineTransformTranslate(
        affineTransform,
        -(layerAnchor.x * size.width ),
        -(layerAnchor.y * size.height)
    );

    return affineTransform;
}

- (CGAffineTransform)affineTransformToLayer:(MALayer *)layer {
    MALayer *parentLayer = [self commonParentLayerWithLayer:layer];

	// FIXME: this is a really naive implementation

    // returns the transformation needed to get from 'fromLayer' to
    // 'parentLayer'
    CGAffineTransform (^transformFromLayer)(MALayer *) = ^(MALayer *fromLayer){
        CGAffineTransform affineTransform = CGAffineTransformIdentity;

        while (fromLayer != parentLayer) {
            // work backwards, getting the transformation from the superlayer to
            // the sublayer
            MALayer *toLayer = fromLayer.superlayer;
            CGAffineTransform invertedTransform = [toLayer affineTransformToImmediateSublayer:fromLayer];

            // then invert that, to get the other direction
            affineTransform = CGAffineTransformConcat(affineTransform, CGAffineTransformInvert(invertedTransform));

            fromLayer = toLayer;
        }

        return affineTransform;
    };

    // get the transformation from self to 'parentLayer'
    CGAffineTransform transformFromSelf = transformFromLayer(self);

    // get the transformation from 'parentLayer' to 'layer'
    CGAffineTransform transformFromOther = transformFromLayer(layer);
    CGAffineTransform transformToOther = CGAffineTransformInvert(transformFromOther);

    // combine the two
    return CGAffineTransformConcat(transformFromSelf, transformToOther);
}

- (CGPoint)convertPoint:(CGPoint)point fromLayer:(MALayer *)layer; {
    CGAffineTransform affineTransform = [layer affineTransformToLayer:self];
    return CGPointApplyAffineTransform(point, affineTransform);
}

- (CGPoint)convertPoint:(CGPoint)point toLayer:(MALayer *)layer; {
    CGAffineTransform affineTransform = [self affineTransformToLayer:layer];
    return CGPointApplyAffineTransform(point, affineTransform);
}

- (CGRect)convertRect:(CGRect)rect fromLayer:(MALayer *)layer; {
    CGAffineTransform affineTransform = [layer affineTransformToLayer:self];
    return CGRectApplyAffineTransform(rect, affineTransform);
}

- (CGRect)convertRect:(CGRect)rect toLayer:(MALayer *)layer; {
    CGAffineTransform affineTransform = [self affineTransformToLayer:layer];
    return CGRectApplyAffineTransform(rect, affineTransform);
}

#pragma mark Displaying and drawing

- (void)display {
	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	size_t height = (size_t)ceil(size.height);

	if (!width || !height)
	    return;

	CGContextRef windowContext = [NSGraphicsContext currentContext].graphicsPort;
	CGLayerRef layer = CGLayerCreateWithContext(windowContext, size, NULL);

	// now pull out the layer's context to actually draw into
	CGContextRef context = CGLayerGetContext(layer);

	// Be sure to set a default fill color, otherwise CGContextSetFillColor behaves oddly (doesn't actually set the color?).
	CGColorRef defaultFillColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetFillColorWithColor(context, defaultFillColor);
	CGColorRelease(defaultFillColor);

	// invoke delegate's drawing logic, if provided
	if ([self.delegate respondsToSelector:@selector(drawLayer:inContext:)])
		[self.delegate drawLayer:self inContext:context];
	else
		[self drawInContext:context];

	// store the drawn CGLayer as the cached contents
	self.contents = (__bridge_transfer id)layer;
}

- (void)displayIfNeeded {
  	if (!self.needsDisplay)
		return;

	// invoke delegate's display logic, if provided
	if ([self.delegate respondsToSelector:@selector(displayLayer:)])
		[self.delegate displayLayer:self];
	else
		[self display];

  	self.needsDisplay = NO;
}

- (void)drawInContext:(CGContextRef)context {

}

- (void)setNeedsDisplay {
  	self.needsDisplay = YES;
}

#pragma mark Rendering

- (void)renderInContext:(CGContextRef)context {
    CGContextSaveGState(context);

  	[self displayIfNeeded];

	CGImageRef image;
	CGLayerRef layer;

	// draw whichever type of contents the layer has
	if ((layer = self.contentsLayer))
		CGContextDrawLayerInRect(context, self.bounds, layer);
	else if ((image = self.contentsImage))
		CGContextDrawImage(context, self.bounds, image);
	else {
		// if it's some unrecognized type, just draw directly into the
		// destination
		[self drawInContext:context];
	}

	CGContextRestoreGState(context);

	// render all sublayers
	for(MALayer *sublayer in [self.sublayers reverseObjectEnumerator]) {
	    CGContextSaveGState(context);

        CGAffineTransform affineTransform = [self affineTransformToImmediateSublayer:sublayer];
        CGContextConcatCTM(context, affineTransform);
		[sublayer renderInContext:context];

		CGContextRestoreGState(context);
	}
}

#pragma mark Sublayer management

- (void)addSublayer:(MALayer *)layer {
  	[layer removeFromSuperlayer];

  	[self.sublayers addObject:layer];
	layer.superlayer = self;
}

- (void)removeFromSuperlayer {
  	[self.superlayer.sublayers removeObjectIdenticalTo:self];
	self.superlayer = nil;
}

- (BOOL)isDescendantOfLayer:(MALayer *)layer {
    NSParameterAssert(layer != nil);

    MALayer *testLayer = self;
    do {
        if (testLayer == layer)
            return YES;

        testLayer = testLayer.superlayer;
    } while (testLayer);

    return NO;
}

- (MALayer *)commonParentLayerWithLayer:(MALayer *)layer {
    // TODO: this is a naive implementation

    MALayer *parentLayer = self;
    do {
        if ([self isDescendantOfLayer:parentLayer] && [layer isDescendantOfLayer:parentLayer])
            return parentLayer;

        parentLayer = parentLayer.superlayer;
    } while (parentLayer);

    return nil;
}

@end
