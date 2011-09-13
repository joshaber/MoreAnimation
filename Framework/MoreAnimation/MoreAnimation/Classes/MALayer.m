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

	// mark layers as needing display right off the bat, since no content has
	// yet been rendered
	self.needsDisplay = YES;

	return self;
}

- (void)dealloc {
	dispatch_release(m_renderQueue);
}

#pragma mark Properties

- (CGRect)bounds {
	return CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

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

@synthesize frame;
@synthesize sublayers;
@synthesize superlayer;
@synthesize delegate;
@synthesize needsDisplay;

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

	// render all sublayers
	for(MALayer *sublayer in [self.sublayers reverseObjectEnumerator]) {
		// TODO: transform CTM to sublayer
		[sublayer renderInContext:context];
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

@end
