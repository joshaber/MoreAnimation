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
	id m_contents;

	dispatch_queue_t m_renderQueue;
}

@property (readonly) CGImageRef contentsImage;
@property (readonly) CGLayerRef contentsLayer;

// publicly readonly
@property (nonatomic, readwrite, strong) NSMutableArray *sublayers;
@property (nonatomic, readwrite, weak) MALayer *superlayer;
@property (nonatomic, readwrite, assign) BOOL needsDisplay;
@end


@implementation MALayer

- (id)init {
	self = [super init];
	if(self == nil) return nil;
	
	m_renderQueue = dispatch_queue_create("MoreAnimation.MALayer", DISPATCH_QUEUE_SERIAL);
	
	self.sublayers = [NSMutableArray array];
	self.needsDisplay = YES;
	
	return self;
}

#pragma mark API

- (id)contents {
  	__block id image = NULL;

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

	if (typeID == CGLayerGetTypeID())
		return obj;
	else
		return NULL;
}

- (void)setContents:(id)contents {
	dispatch_async(m_renderQueue, ^{
		m_contents = contents;
	});
}

@synthesize frame;
@synthesize sublayers;
@synthesize superlayer;
@synthesize delegate;
@synthesize needsDisplay;

- (void)dealloc {	
	dispatch_release(m_renderQueue);
}

- (void)display {
	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	size_t height = (size_t)ceil(size.height);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

	CGContextRef context = CGBitmapContextCreate(
		NULL,
		width,
		height,
		8,
		4 * width,
		colorSpace,
		kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast
	);

	CGLayerRef layer = CGLayerCreateWithContext(context, size, NULL);

	CGContextRef newContext = CGLayerGetContext(layer);
	CGContextRelease(context);
	context = newContext;

	CGContextTranslateCTM(context, 0.0f, size.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	
	// Be sure to set a default fill color, otherwise CGContextSetFillColor behaves oddly (doesn't actually set the color?).
	CGColorRef defaultFillColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetFillColorWithColor(context, defaultFillColor);
	CGColorRelease(defaultFillColor);

	CGColorSpaceRelease(colorSpace);

	if ([self.delegate respondsToSelector:@selector(drawLayer:inContext:)])
		[self.delegate drawLayer:self inContext:context];
	else
		[self drawInContext:context];

	self.contents = (__bridge_transfer id)layer;
}

- (void)displayIfNeeded {
  	if (!self.needsDisplay)
		return;
	
	if ([self.delegate respondsToSelector:@selector(displayLayer:)])
		[self.delegate displayLayer:self];
	else
		[self display];

  	self.needsDisplay = NO;
}

- (void)setNeedsDisplay {
  	self.needsDisplay = YES;
}

- (void)drawInContext:(CGContextRef)context {
	NSImage *nsImage = [NSImage imageNamed:@"test"];
	CGContextDrawImage(context, self.bounds, [nsImage CGImageForProposedRect:NULL context:NULL hints:nil]);
	
	CGContextSetFillColor(context, (CGFloat []) { 0.0f, 0.0f, 1.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(20.0f, 20.0f, 200.0f, 200.0f));
	
	CGContextSetFillColor(context, (CGFloat []) { 1.0f, 0.0f, 0.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(70.0f, 70.0f, 100.0f, 100.0f));
}

- (void)renderInContext:(CGContextRef)context {
  	[self displayIfNeeded];

	CGImageRef image;
	CGLayerRef layer;

	if ((layer = self.contentsLayer))
		CGContextDrawLayerInRect(context, self.bounds, layer);
	else if ((image = self.contentsImage))
		CGContextDrawImage(context, self.bounds, image);
	else
		[self drawInContext:context];
	
	for(MALayer *sublayer in [self.sublayers reverseObjectEnumerator]) {
		[sublayer renderInContext:context];
	}
}

- (CGRect)bounds {
	return CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

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
