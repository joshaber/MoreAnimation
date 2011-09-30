//
//  MAHostingCALayer.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-29.
//  Copyright (c) 2011 Übermind, Inc. All rights reserved.
//

#import <MoreAnimation/MAHostingCALayer.h>
#import <MoreAnimation/MALayer.h>
#import <libkern/OSAtomic.h>
#import "EXTScope.h"

@interface MAHostingCALayer () {
	MALayer *m_MALayer;
	OSSpinLock m_MALayerSpinLock;
}

@end

@implementation MAHostingCALayer

#pragma mark Properties

@synthesize MALayer = m_MALayer;

- (id)contents {
  	return self.MALayer.contents;
}

- (void)setContents:(id)value {
  	self.MALayer.contents = value;
}

- (MALayer *)MALayer {
 	OSSpinLockLock(&m_MALayerSpinLock);
	@onExit {
		OSSpinLockUnlock(&m_MALayerSpinLock);
	};

  	return m_MALayer;
}

- (void)setMALayer:(MALayer *)layer {
  	__weak CALayer *weakSelf = self;

  	layer.needsRenderBlock = ^(MALayer *layer){
		[weakSelf setNeedsDisplay];
	};

  	OSSpinLockLock(&m_MALayerSpinLock);
	m_MALayer = layer;
  	OSSpinLockUnlock(&m_MALayerSpinLock);
}

- (BOOL)needsDisplayOnBoundsChange {
  	return self.MALayer.needsDisplayOnBoundsChange;
}

- (void)setNeedsDisplayOnBoundsChange:(BOOL)value {
  	self.MALayer.needsDisplayOnBoundsChange = value;
}

- (BOOL)isOpaque {
  	return self.MALayer.opaque;
}

- (void)setOpaque:(BOOL)value {
  	self.MALayer.opaque = value;
}

#pragma mark Layout

- (void)layoutSublayers {
  	self.MALayer.frame = self.bounds;
}

#pragma mark Rendering and drawing

- (void)display {
  	// don't draw anything -- depend on MALayer caching
}

- (void)drawInContext:(CGContextRef)context {
  	[self.MALayer drawInContext:context];
}

- (void)renderInContext:(CGContextRef)context {
  	[self.MALayer renderInContext:context];
}
@end
