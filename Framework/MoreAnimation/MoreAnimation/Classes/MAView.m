//
//  MAView.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAView.h"
#import "MALayer.h"

// unique pointer for KVO context
static char * const MAViewNeedsDisplayContext = "MAViewNeedsDisplayContext";

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

- (void)dealloc {
  	// make sure to remove KVO observer
  	self.contentLayer = nil;
}

#pragma mark Properties

- (void)setContentLayer:(MALayer *)layer {
  	if (layer != m_contentLayer) {
		[m_contentLayer removeObserver:self forKeyPath:@"needsDisplay" context:MAViewNeedsDisplayContext];
		[layer addObserver:self forKeyPath:@"needsDisplay" options:NSKeyValueObservingOptionNew context:MAViewNeedsDisplayContext];
		
		m_contentLayer = layer;
	}
}

@synthesize contentLayer = m_contentLayer;

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
  	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	[self.contentLayer renderInContext:context];
}

#pragma mark Layout

- (void)layout {
  	[super layout];

	CGRect bounds = NSRectToCGRect(self.bounds);
    self.contentLayer.bounds = bounds;
	[self.contentLayer setNeedsDisplay];
}

#pragma mark Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  	if (context != MAViewNeedsDisplayContext) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}

	NSNumber *newValue = [change objectForKey:NSKeyValueChangeNewKey];
	if ([newValue boolValue])
		[self setNeedsDisplay:YES];
}

@end
