//
//  MAView.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
//

#import "MAView.h"
#import "MALayer.h"

@interface MAView () {
	MALayer *m_contentLayer;
}

@end

@implementation MAView

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		self.contentLayer = [[MALayer alloc] init];
    }
    
    return self;
}

#pragma mark Properties

- (void)setContentLayer:(MALayer *)layer {
	m_contentLayer.needsRenderBlock = nil;
	m_contentLayer = layer;

	__weak id weakSelf = self;
	__weak MALayer *weakLayer = layer;

	layer.needsRenderBlock = ^(MALayer *layerNeedingRender){
		if (layerNeedingRender == weakLayer)
			[weakSelf setNeedsDisplay:YES];
	};
}

@synthesize contentLayer = m_contentLayer;

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
	CGRect bounds = NSRectToCGRect(self.bounds);
    self.contentLayer.bounds = bounds;

  	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	[self.contentLayer renderInContext:context];
}

@end
