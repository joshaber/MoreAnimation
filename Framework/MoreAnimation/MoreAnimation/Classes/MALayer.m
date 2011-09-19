//
//  MALayer.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/9/11.
//  Released into the public domain.
//

#import "MALayer.h"
#import "MALayer+Private.h"
#import "EXTScope.h"
#import <libkern/OSAtomic.h>

/**
 * The maximum delta between two geometry values that will not be considered
 * a change (due to the inherent inaccuracy of floating-point calculations).
 */
static const CGFloat MALayerGeometryDifferenceTolerance = 0.000001;

@interface MALayer () {
	/**
	 * A spin lock used to synchronize access to layer contents (below).
	 */
	OSSpinLock m_contentsSpinLock;

	/**
	 * The contents of this layer. This may be any object type needed to render
	 * the layer efficiently, including a \c CGImageRef or \c CGLayerRef.
	 *
	 * Use \c CFGetTypeID() or an \c isKindOfClass: check to determine this
	 * object's type before attempting to use it.
	 */
	id m_contents;

	/**
	 * A cached rendering of this layer's entire subtree. Protected by the
	 * contents spin lock.
	 */
	CGLayerRef m_cachedLayerTree;

	/**
	 * A spin lock used to synchronize mutation to the sublayers array (below).
	 */
	OSSpinLock m_sublayersSpinLock;

	/**
	 * Sublayers. Access to this array should be protected using the render
	 * dispatch queue.
	 */
	NSMutableArray *m_sublayers;

	/**
	 * A spin lock used to synchronize access to all the atomic geometry
	 * properties (below).
	 */
	OSSpinLock m_geometrySpinLock;

	/**
	 * Geometry properties. Access to these should be protected using the
	 * geometry spin lock.
	 */
	CGPoint m_position;
	CGFloat m_zPosition;
	CGPoint m_anchorPoint;
	CGFloat m_anchorPointZ;
	CGFloat m_contentsScale;
	CGRect m_bounds;
	CATransform3D m_sublayerTransform;
	CATransform3D m_transform;

	/**
	 * The number of threads currently rendering. Used for the #rendering
	 * property.
	 */
	volatile int32_t m_rendererCount;
}

#if 0
/**
 * Lays out the receiver and all of its descendant layers concurrently.
 */
- (void)concurrentlyLayoutLayerTree;
#endif

/**
 * Draws the receiver into \a context, using #drawInContext: or the #delegate.
 */
- (void)drawSelfInContext:(CGContextRef)context;

/**
 * Removes \a layer from the receiver's list of sublayers.
 */
- (void)removeSublayer:(MALayer *)layer;

/**
 * Renders the receiver and its sublayers into \a context, caching the layer
 * contents or subtree as appropriate.
 */
- (void)renderInContextCached:(CGContextRef)context;

/**
 * Renders the receiver and its sublayers into \a context, without caching the
 * layer contents, the contents of any sublayers, or the subtree as a whole.
 */
- (void)renderInContextUncached:(CGContextRef)context;

/**
 * Renders a cached representation of the receiver into \a context. If no cached
 * representation exists, the receiver is drawn directly into \a context.
 *
 * This method does not render sublayers.
 */
- (void)renderSelfInContext:(CGContextRef)context;

/**
 * Returns the affine transformation needed to move into the coordinate system
 * of the receiver from that of its superlayer.
 */
@property (readonly) CGAffineTransform affineTransformFromSuperlayer;

/**
 * A cached rendering of this layer's entire subtree.
 */
@property CGLayerRef cachedLayerTree;

/**
 * Whether the layer or its subtree has changed since the last time it was
 * rendered. This becomes \c YES any time #setNeedsRender is invoked.
 */
@property (assign) BOOL changedSinceLastRender;

/**
 * Whether the layer is currently rendering (on the current or another thread).
 * If this is \c YES, #setNeedsRender does nothing.
 */
@property (readonly, getter = isRendering) BOOL rendering;

// publicly readonly
@property (readwrite, unsafe_unretained) MALayer *superlayer;
@property (readwrite, assign) BOOL needsDisplay;
@property (readwrite, assign) BOOL needsLayout;
@end


@implementation MALayer

#pragma mark Lifecycle

- (id)init {
	self = [super init];
	if(self == nil) return nil;

	// initialize geometry
	self.anchorPoint = CGPointMake(0.5, 0.5);
	self.transform = CATransform3DIdentity;
	self.sublayerTransform = CATransform3DIdentity;

	// mark layer as needing display right off the bat, since no content has
	// yet been rendered
	self.needsDisplay = YES;

	return self;
}

- (void)dealloc {
  	self.cachedLayerTree = NULL;
}

#pragma mark Key-value coding

+ (NSSet *)keyPathsForValuesAffectingFrame {
	return [NSSet setWithObjects:@"bounds", @"anchorPoint", @"position", nil];
}

#pragma mark Properties

- (id)contents {
  	OSSpinLockLock(&m_contentsSpinLock);
	@onExit {
		OSSpinLockUnlock(&m_contentsSpinLock);
	};

  	return m_contents;
}

- (void)setContents:(id)contents {
  	[self willChangeValueForKey:@"contents"];
	@onExit {
		[self didChangeValueForKey:@"contents"];
	};

  	BOOL changed = NO;

	// layer contents should only be read/written from a single thread at a time
	OSSpinLockLock(&m_contentsSpinLock);
	if (contents != m_contents) {
		m_contents = contents;
		changed = YES;
	}

	OSSpinLockUnlock(&m_contentsSpinLock);

	if (changed)
		[self setNeedsRender];
}

- (CGLayerRef)cachedLayerTree {
  	OSSpinLockLock(&m_contentsSpinLock);
	@onExit {
		OSSpinLockUnlock(&m_contentsSpinLock);
	};

  	return m_cachedLayerTree;
}

- (void)setCachedLayerTree:(CGLayerRef)tree {
	OSSpinLockLock(&m_contentsSpinLock);

	CGLayerRelease(m_cachedLayerTree);
	m_cachedLayerTree = CGLayerRetain(tree);

	OSSpinLockUnlock(&m_contentsSpinLock);
}

- (CGAffineTransform)affineTransform {
    return CATransform3DGetAffineTransform(self.transform);
}

- (void)setAffineTransform:(CGAffineTransform)affineTransform {
    self.transform = CATransform3DMakeAffineTransform(affineTransform);
}

- (CGRect)frame {
  	// apply geometry spin lock to freeze current values
  	OSSpinLockLock(&m_geometrySpinLock);

	// don't use properties here, to avoid recursively locking the spin lock
    CGSize size = m_bounds.size;
    CGPoint anchor = m_anchorPoint;
    CGPoint originalPosition = m_position;

	OSSpinLockUnlock(&m_geometrySpinLock);

    CGPoint transformedAnchorPoint = CGPointMake(
        anchor.x * size.width,
        anchor.y * size.height
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
  	[self willChangeValueForKey:@"frame"];
	@onExit {
		[self didChangeValueForKey:@"frame"];
		[self setNeedsRender];
	};

  	// apply geometry spin lock to protect the values we're setting
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};
	
	// don't use properties here, to avoid recursively locking the spin lock
    CGSize size = rect.size;
    m_bounds = CGRectMake(0, 0, size.width, size.height);

    CGPoint anchor = m_anchorPoint;

    CGPoint transformedAnchorPoint = CGPointMake(
        anchor.x * size.width,
        anchor.y * size.height
    );

    m_position = CGPointMake(
        CGRectGetMinX(rect) + transformedAnchorPoint.x,
        CGRectGetMinY(rect) + transformedAnchorPoint.y
    );
}

- (CGAffineTransform)affineTransformFromSuperlayer {
	OSSpinLockLock(&m_geometrySpinLock);

    CGPoint layerAnchor = m_anchorPoint;
    CGPoint layerPosition = m_position;
    CGSize size = m_bounds.size;
	CGAffineTransform transformToApply = CATransform3DGetAffineTransform(m_transform);

	OSSpinLockUnlock(&m_geometrySpinLock);

    // translate to our anchor point
    CGAffineTransform affineTransform = CGAffineTransformMakeTranslation(
        layerPosition.x + ((layerAnchor.x - 0.5) * size.width),
        layerPosition.y + ((layerAnchor.y - 0.5) * size.height)
    );

    // apply our affineTransform
    affineTransform = CGAffineTransformConcat(transformToApply, affineTransform);

    // translate back to the origin in the our coordinate system
    affineTransform = CGAffineTransformTranslate(
        affineTransform,
        -(layerAnchor.x * size.width ),
        -(layerAnchor.y * size.height)
    );

    return affineTransform;
}

- (CGPoint)position {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_position;
}

- (void)setPosition:(CGPoint)value {
  	[self willChangeValueForKey:@"position"];
	@onExit {
		[self didChangeValueForKey:@"position"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (!CGPointEqualToPoint(m_position, value)) {
		m_position = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self.superlayer setNeedsRender];
}

- (CGFloat)zPosition {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_zPosition;
}

- (void)setZPosition:(CGFloat)value {
  	[self willChangeValueForKey:@"zPosition"];
	@onExit {
		[self didChangeValueForKey:@"zPosition"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (fabs(m_zPosition - value) > MALayerGeometryDifferenceTolerance) {
		m_zPosition = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self.superlayer setNeedsRender];
}

- (CGPoint)anchorPoint {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_anchorPoint;
}

- (void)setAnchorPoint:(CGPoint)value {
  	[self willChangeValueForKey:@"anchorPoint"];
	@onExit {
		[self didChangeValueForKey:@"anchorPoint"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (!CGPointEqualToPoint(m_anchorPoint, value)) {
		m_anchorPoint = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self.superlayer setNeedsRender];
}

- (CGFloat)anchorPointZ {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_anchorPointZ;
}

- (void)setAnchorPointZ:(CGFloat)value {
  	[self willChangeValueForKey:@"anchorPointZ"];
	@onExit {
		[self didChangeValueForKey:@"anchorPointZ"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (fabs(m_anchorPointZ - value) > MALayerGeometryDifferenceTolerance) {
		m_anchorPointZ = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self.superlayer setNeedsRender];
}

- (CGRect)bounds {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_bounds;
}

- (void)setBounds:(CGRect)value {
  	[self willChangeValueForKey:@"bounds"];
	@onExit {
		[self didChangeValueForKey:@"bounds"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (!CGRectEqualToRect(m_bounds, value)) {
		m_bounds = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self setNeedsRender];
}

- (CATransform3D)sublayerTransform {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_sublayerTransform;
}

- (void)setSublayerTransform:(CATransform3D)value {
  	[self willChangeValueForKey:@"sublayerTransform"];
	@onExit {
		[self didChangeValueForKey:@"sublayerTransform"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (!CATransform3DEqualToTransform(m_sublayerTransform, value)) {
		m_sublayerTransform = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self setNeedsLayout];
}

- (CATransform3D)transform {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_transform;
}

- (void)setTransform:(CATransform3D)value {
  	[self willChangeValueForKey:@"transform"];
	@onExit {
		[self didChangeValueForKey:@"transform"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (!CATransform3DEqualToTransform(m_transform, value)) {
		m_transform = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self.superlayer setNeedsRender];
}

- (CGFloat)contentsScale {
	OSSpinLockLock(&m_geometrySpinLock);
	@onExit {
		OSSpinLockUnlock(&m_geometrySpinLock);
	};

	return m_contentsScale;
}

- (void)setContentsScale:(CGFloat)value {
  	[self willChangeValueForKey:@"contentsScale"];
	@onExit {
		[self didChangeValueForKey:@"contentsScale"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_geometrySpinLock);
	if (fabs(m_contentsScale - value) > MALayerGeometryDifferenceTolerance) {
		m_contentsScale = value;
		changed = YES;
	}

	OSSpinLockUnlock(&m_geometrySpinLock);

	if (changed)
		[self setNeedsDisplay];
}

- (NSArray *)sublayers {
	OSSpinLockLock(&m_sublayersSpinLock);
	@onExit {
		OSSpinLockUnlock(&m_sublayersSpinLock);
	};

	return [m_sublayers copy];
}

- (NSArray *)orderedSublayers {
	OSSpinLockLock(&m_sublayersSpinLock);

	NSArray *orderedSublayers = [m_sublayers
		sortedArrayWithOptions:NSSortConcurrent | NSSortStable
		usingComparator:^ NSComparisonResult (MALayer *left, MALayer *right){
			CGFloat zPosDifference = left.zPosition - right.zPosition;

			// if the zPosition of the left layer is greater than the right
			// layer...
			if (zPosDifference > MALayerGeometryDifferenceTolerance) {
				// the left layer should be on top
				return NSOrderedDescending;
			} else if (zPosDifference < -MALayerGeometryDifferenceTolerance) {
				// or, the other way, then the right layer
				return NSOrderedAscending;
			} else {
				// if the zPositions are "equal," preserve ordering based on
				// position in sublayers array
				return NSOrderedSame;
			}
		}
	];
	
	OSSpinLockUnlock(&m_sublayersSpinLock);

	return orderedSublayers;
}

- (BOOL)isRendering {
  	return (m_rendererCount > 0);
}

@synthesize superlayer = m_superlayer;
@synthesize delegate = m_delegate;
@synthesize needsDisplay = m_needsDisplay;
@synthesize needsLayout = m_needsLayout;
@synthesize needsRenderBlock = m_needsRenderBlock;
@synthesize opaque = m_opaque;
@synthesize changedSinceLastRender;

#pragma mark NSObject overrides

- (NSString *)description {
  	NSString *superlayerString;
	if (self.superlayer) {
		superlayerString = [NSString stringWithFormat:@"<%@: %p>", [self.superlayer class], (__bridge void *)self.superlayer];
	} else {
		superlayerString = @"nil";
	}

  	return [NSString stringWithFormat:@"<%@: %p>{ frame: %@, superlayer: %@ }", [self class], (__bridge void *)self, NSStringFromRect(NSRectFromCGRect(self.frame)), superlayerString];
}

#pragma mark Coordinate systems and transformations

- (CGAffineTransform)affineTransformToLayer:(MALayer *)layer {
    MALayer *parentLayer = [self ancestorSharedWithLayer:layer];
	NSAssert(parentLayer != nil, @"layers must share an ancestor in order for an affine transform between them to be valid");

	// FIXME: this is a really naive implementation

    // returns the transformation needed to get from 'fromLayer' to
    // 'parentLayer'
    CGAffineTransform (^transformFromLayer)(MALayer *) = ^(MALayer *fromLayer){
        CGAffineTransform affineTransform = CGAffineTransformIdentity;

        while (fromLayer != parentLayer) {
            // work backwards, getting the transformation from the superlayer to
            // the sublayer
            CGAffineTransform invertedTransform = fromLayer.affineTransformFromSuperlayer;

            // then invert that, to get the other direction
            affineTransform = CGAffineTransformConcat(affineTransform, CGAffineTransformInvert(invertedTransform));

            fromLayer = fromLayer.superlayer;
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

	self.contents = nil;

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

	[self drawSelfInContext:context];

	// store the drawn CGLayer as the cached contents
	self.contents = (__bridge_transfer id)layer;
}

- (void)displayIfNeeded {
	if (!self.needsDisplay)
		return;

	// invoke delegate's display logic, if provided
	id<MALayerDelegate> dg = self.delegate;
	if ([dg respondsToSelector:@selector(displayLayer:)])
		[dg displayLayer:self];
	else
		[self display];

	self.needsDisplay = NO;
}

- (void)drawInContext:(CGContextRef)context {
}

- (void)drawSelfInContext:(CGContextRef)context {
  	CGRect bounds = self.bounds;

	CGContextSaveGState(context);
	CGContextClipToRect(context, bounds);

	// invoke delegate's drawing logic, if provided
	id<MALayerDelegate> dg = self.delegate;
	if ([dg respondsToSelector:@selector(drawLayer:inContext:)])
		[dg drawLayer:self inContext:context];
	else
		[self drawInContext:context];

	#if MA_LAYER_DEBUG
	CGFloat width = bounds.size.width;
	CGFloat height = bounds.size.height;

	CGColorRef whiteColor = CGColorCreateGenericGray(1, 1);
	CGContextSetStrokeColorWithColor(context, whiteColor);
	CGColorRelease(whiteColor);

	CGContextSetLineWidth(context, 2);
	CGContextSetLineCap(context, kCGLineCapSquare);

	CGContextBeginPath(context);

	// draw a 10x10 grid over the layer
	for (CGFloat x = 0;x - width < 0.001;x += width / 10) {
		CGContextMoveToPoint(context, x, 0);
		CGContextAddLineToPoint(context, x, height);
	}

	for (CGFloat y = 0;y - height < 0.001;y += height / 10) {
		CGContextMoveToPoint(context, 0, y);
		CGContextAddLineToPoint(context, width, y);
	}

	CGContextStrokePath(context);
	#endif

	CGContextRestoreGState(context);
}

- (void)setNeedsDisplay {
  	self.needsDisplay = YES;
	[self setNeedsRender];
}

#pragma mark Layout

- (void)layoutIfNeeded {
  	if (!self.needsLayout)
		return;
	
	#if 0
  	MALayer *lastNeedingLayout = self;
	MALayer *nextLayer = self.superlayer;

	while (nextLayer.needsLayout) {
		lastNeedingLayout = nextLayer;
		nextLayer = nextLayer.superlayer;
	}

	[lastNeedingLayout concurrentlyLayoutLayerTree];
	#endif
	
	[self layoutSublayers];
	self.needsLayout = NO;
}

#if 0
- (void)concurrentlyLayoutLayerTree {
	[self layoutSublayers];
	[self.sublayers
		enumerateObjectsWithOptions:NSEnumerationConcurrent
		usingBlock:^(MALayer *layer, NSUInteger index, BOOL *stop){
			[layer concurrentlyLayoutLayerTree];
		}
	];
}
#endif

- (void)layoutSublayers {
}

- (void)setNeedsLayout {
  	self.needsLayout = YES;
	[self setNeedsRender];
}

#pragma mark Rendering

- (void)renderInContext:(CGContextRef)context {
  	[self renderInContext:context allowCaching:YES];
}

- (void)renderInContext:(CGContextRef)context allowCaching:(BOOL)allowCaching {
  	OSAtomicIncrement32Barrier(&m_rendererCount);
	@onExit {
		OSAtomicDecrement32Barrier(&m_rendererCount);
	};

	[self layoutIfNeeded];

	if (allowCaching) {
		OSSpinLockLock(&m_sublayersSpinLock);
		NSUInteger sublayerCount = [m_sublayers count];
		OSSpinLockUnlock(&m_sublayersSpinLock);

		/*
		 * If a layer has sublayers, has not changed since the last time it was
		 * rendered, and no ancestor is already performing subtree caching, we
		 * should try to cache the subtree.
		 */

		BOOL shouldCacheSubtree = (sublayerCount > 0 && !self.changedSinceLastRender);
		if (shouldCacheSubtree) {
			CGLayerRef subtreeLayer = self.cachedLayerTree;
			CGRect bounds = self.bounds;

			if (!subtreeLayer) {
				subtreeLayer = CGLayerCreateWithContext(context, bounds.size, NULL);
				CGContextRef subtreeLayerContext = CGLayerGetContext(subtreeLayer);
				
				// Be sure to set a default fill color, otherwise CGContextSetFillColor behaves oddly (doesn't actually set the color?).
				CGColorRef defaultFillColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
				CGContextSetFillColorWithColor(subtreeLayerContext, defaultFillColor);
				CGColorRelease(defaultFillColor);

				[self renderInContextUncached:subtreeLayerContext];

				self.cachedLayerTree = subtreeLayer;
				CGLayerRelease(subtreeLayer);
			}

			BOOL opaque = self.opaque;
			if (opaque) {
				CGContextSaveGState(context);
				CGContextSetBlendMode(context, kCGBlendModeCopy);
			}

			CGContextDrawLayerInRect(context, bounds, subtreeLayer);

			if (opaque) {
				CGContextRestoreGState(context);
			}
		} else {
			/*
			 * If no ancestor is performing subtree caching, we should fall back
			 * to trying to cache just this layer's contents.
			 */
			[self renderInContextCached:context];
		}
	} else {
		/*
		 * If an ancestor is performing subtree caching, we should discard our
		 * caches and draw directly into its cache.
		 */
		[self renderInContextUncached:context];
	}

	// clear changed flag so that we can tell if a change occurs between now and
	// next time
	self.changedSinceLastRender = NO;
}

- (void)setNeedsRender {
  	if (self.rendering)
		return;
	
  	self.cachedLayerTree = NULL;
	self.changedSinceLastRender = YES;

  	MALayerNeedsRenderBlock callback = self.needsRenderBlock;
	if (callback) {
		callback(self);
	}

	[self.superlayer setNeedsRender];
}

- (void)renderInContextCached:(CGContextRef)context {
	// if we're on the main thread, increase rendering priority to avoid
	// blocking as much as possible
	long renderingPriority = DISPATCH_QUEUE_PRIORITY_DEFAULT;
	if (dispatch_get_current_queue() == dispatch_get_main_queue())
		renderingPriority = DISPATCH_QUEUE_PRIORITY_HIGH;

	// start rendering sublayers
	NSArray *orderedSublayers = self.orderedSublayers;
	NSUInteger sublayerCount = [orderedSublayers count];

	volatile int32_t *sublayerIndicesRendered = calloc(sublayerCount, sizeof(*sublayerIndicesRendered));
	@onExit {
		free((void *)sublayerIndicesRendered);
	};

	dispatch_queue_t sublayerRenderQueue = dispatch_get_global_queue(renderingPriority, 0);
	dispatch_semaphore_t sublayerSemaphore = dispatch_semaphore_create(0);
	@onExit {
		dispatch_release(sublayerSemaphore);
	};

	[orderedSublayers enumerateObjectsUsingBlock:^(MALayer *sublayer, NSUInteger index, BOOL *stop){
		dispatch_async(sublayerRenderQueue, ^{
			[sublayer displayIfNeeded];

			OSAtomicIncrement32Barrier(sublayerIndicesRendered + index);
			dispatch_semaphore_signal(sublayerSemaphore);
		});
	}];

	// render self synchronously while sublayers are rendering concurrently
	@autoreleasepool {
		// TODO: if sublayers are going to perform subtree caching, this is
		// a waste
		[self displayIfNeeded];
		[self renderSelfInContext:context];
	}

	// render all sublayers, blocking on any that are still displaying
	[orderedSublayers enumerateObjectsUsingBlock:^(MALayer *sublayer, NSUInteger index, BOOL *stop){
		// wait on this sublayer to be rendered
		while (!sublayerIndicesRendered[index]) {
			dispatch_semaphore_wait(sublayerSemaphore, DISPATCH_TIME_FOREVER);
		}

		@autoreleasepool {
			CGContextSaveGState(context);

			CGAffineTransform affineTransform = [self affineTransformToLayer:sublayer];
			CGContextConcatCTM(context, affineTransform);
			[sublayer renderInContext:context allowCaching:YES];

			CGContextRestoreGState(context);
		}
	}];
}
	
- (void)renderInContextUncached:(CGContextRef)context {
  	// clear contents
	OSSpinLockLock(&m_contentsSpinLock);
	m_contents = nil;
	OSSpinLockUnlock(&m_contentsSpinLock);

	// clear any subtree caching
	self.cachedLayerTree = NULL;

	[self renderSelfInContext:context];

	[self.orderedSublayers enumerateObjectsUsingBlock:^(MALayer *sublayer, NSUInteger index, BOOL *stop){
		CGContextSaveGState(context);

		CGAffineTransform affineTransform = [self affineTransformToLayer:sublayer];
		CGContextConcatCTM(context, affineTransform);
		[sublayer renderInContext:context allowCaching:NO];

		CGContextRestoreGState(context);
	}];
}

- (void)renderSelfInContext:(CGContextRef)context {
	id contents = self.contents;
	BOOL foundMatch = NO;

	if (contents) {
		CFTypeID typeID = CFGetTypeID((__bridge CFTypeRef)contents);
		CGRect bounds = self.bounds;

		BOOL opaque = self.opaque;
		if (opaque) {
			CGContextSaveGState(context);
			CGContextSetBlendMode(context, kCGBlendModeCopy);
		}

		// draw whichever type of contents the layer has
		if (typeID == CGLayerGetTypeID()) {
			CGContextDrawLayerInRect(context, bounds, (__bridge CGLayerRef)contents);
			foundMatch = YES;
		} else if (typeID == CGImageGetTypeID()) {
			CGContextDrawImage(context, bounds, (__bridge CGImageRef)contents);
			foundMatch = YES;
		}

		if (opaque) {
			CGContextRestoreGState(context);
		}
	}

	if (!foundMatch) {
		[self drawSelfInContext:context];
	}
}

#pragma mark Sublayer management

- (void)addSublayer:(MALayer *)layer {
  	NSParameterAssert(layer != nil);

  	[layer removeFromSuperlayer];

	OSSpinLockLock(&m_sublayersSpinLock);
	{
		if (![m_sublayers count])
			m_sublayers = [NSMutableArray array];

		[m_sublayers addObject:layer];
	}
	OSSpinLockUnlock(&m_sublayersSpinLock);

	layer.superlayer = self;
	[self setNeedsLayout];
}

- (void)insertSublayer:(MALayer *)layer above:(MALayer *)otherLayer {
  	NSParameterAssert(layer != nil);
  	NSParameterAssert(otherLayer != nil);
	NSParameterAssert(otherLayer.superlayer == self);

  	[layer removeFromSuperlayer];

	OSSpinLockLock(&m_sublayersSpinLock);
	{
		NSUInteger existingIndex = [m_sublayers indexOfObjectIdenticalTo:otherLayer];
		[m_sublayers insertObject:layer atIndex:existingIndex + 1];
	}
	OSSpinLockUnlock(&m_sublayersSpinLock);

	layer.superlayer = self;
	[self setNeedsLayout];
}

- (void)insertSublayer:(MALayer *)layer atIndex:(NSUInteger)index; {
  	NSParameterAssert(layer != nil);

  	[layer removeFromSuperlayer];

	OSSpinLockLock(&m_sublayersSpinLock);
	{
		if (![m_sublayers count]) {
			NSAssert(index == 0, @"index is out-of-bounds for sublayers array");
			m_sublayers = [NSMutableArray array];
		}

		[m_sublayers insertObject:layer atIndex:index];
	}
	OSSpinLockUnlock(&m_sublayersSpinLock);

	layer.superlayer = self;
	[self setNeedsLayout];
}

- (void)insertSublayer:(MALayer *)layer below:(MALayer *)otherLayer {
  	NSParameterAssert(layer != nil);
	NSParameterAssert(otherLayer != nil);
	NSParameterAssert(otherLayer.superlayer == self);

  	[layer removeFromSuperlayer];

	OSSpinLockLock(&m_sublayersSpinLock);
	{
		NSUInteger existingIndex = [m_sublayers indexOfObjectIdenticalTo:otherLayer];
		[m_sublayers insertObject:layer atIndex:existingIndex];
	}
	OSSpinLockUnlock(&m_sublayersSpinLock);

	layer.superlayer = self;
	[self setNeedsLayout];
}

- (void)removeFromSuperlayer {
  	MALayer *superlayer = self.superlayer;
	self.superlayer = nil;

	[superlayer removeSublayer:self];
}

- (void)removeSublayer:(MALayer *)sublayer {
	OSSpinLockLock(&m_sublayersSpinLock);
	{
		[m_sublayers removeObjectIdenticalTo:sublayer];
		if (![m_sublayers count])
			m_sublayers = nil;
	}
	OSSpinLockUnlock(&m_sublayersSpinLock);

	[self setNeedsLayout];
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

- (MALayer *)ancestorSharedWithLayer:(MALayer *)layer {
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
