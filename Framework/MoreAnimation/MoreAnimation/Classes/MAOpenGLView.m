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

@implementation MAOpenGLView


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

	CGRect bounds = NSRectToCGRect(self.frame);
    self.contentLayer.bounds = bounds;
//	self.contentLayer.frame = CGRectInset(bounds, 50, 50);

	// TODO: we shouldn't always force redisplay
	[self.contentLayer display];

	[self.contentLayer.sublayers enumerateObjectsUsingBlock:^(MALayer *layer, NSUInteger index, BOOL *stop) {
		layer.bounds = bounds;
		[layer display];
	}];

	[self setNeedsDisplay:YES];
}


#pragma mark API

@synthesize contentLayer;

@end
