//
//  MAOpenGLView.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Released into the public domain.
//

#import "MAOpenGLView.h"
#import "MAOpenGLLayer.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

@interface MAOpenGLView () {
	MAOpenGLLayer *m_contentLayer;
}

@end

@implementation MAOpenGLView

#pragma mark Properties

- (void)setContentLayer:(MAOpenGLLayer *)layer {
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

@end
