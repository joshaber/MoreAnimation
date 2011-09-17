//
//  MAOpenGLView.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLView.h"
#import "MAOpenGLLayer.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

// unique pointer for KVO context
static char * const MAOpenGLViewNeedsDisplayContext = "MAOpenGLViewNeedsDisplayContext";

@interface MAOpenGLView () {
	MAOpenGLLayer *m_contentLayer;
}

@end

@implementation MAOpenGLView

- (void)dealloc {
  	// make sure to remove KVO observer
  	self.contentLayer = nil;
}

#pragma mark Properties

- (void)setContentLayer:(MAOpenGLLayer *)layer {
  	if (layer != m_contentLayer) {
		[m_contentLayer removeObserver:self forKeyPath:@"needsDisplay" context:MAOpenGLViewNeedsDisplayContext];
		[m_contentLayer removeObserver:self forKeyPath:@"needsLayout" context:MAOpenGLViewNeedsDisplayContext];
		[layer addObserver:self forKeyPath:@"needsDisplay" options:NSKeyValueObservingOptionNew context:MAOpenGLViewNeedsDisplayContext];
		[layer addObserver:self forKeyPath:@"needsLayout" options:NSKeyValueObservingOptionNew context:MAOpenGLViewNeedsDisplayContext];
		
		m_contentLayer = layer;
	}
}

@synthesize contentLayer = m_contentLayer;

#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect {
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();

	[self.contentLayer renderInGLContext:self.openGLContext pixelFormat:self.pixelFormat];
	[[self openGLContext] flushBuffer];
}

#pragma mark NSOpenGLView

- (void)prepareOpenGL {
	[super prepareOpenGL];

	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	glEnable(GL_TEXTURE_2D);

	self.contentLayer = [[MAOpenGLLayer alloc] init];
}

- (void)reshape {
	[super reshape];

	glViewport(0, 0, (GLsizei) self.bounds.size.width, (GLsizei) self.bounds.size.height);

	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	gluOrtho2D(0.0f, self.bounds.size.width, 0.0f, self.bounds.size.height);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	CGRect bounds = NSRectToCGRect(self.bounds);
    self.contentLayer.bounds = bounds;
	[self.contentLayer setNeedsDisplay];
}

#pragma mark Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  	if (context != MAOpenGLViewNeedsDisplayContext) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}

	NSNumber *newValue = [change objectForKey:NSKeyValueChangeNewKey];
	if ([newValue boolValue])
		[self setNeedsDisplay:YES];
}

@end
