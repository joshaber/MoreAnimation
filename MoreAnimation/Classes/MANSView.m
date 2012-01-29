//
//  MANSView.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MANSView.h"
#import "MALayer.h"


@implementation MANSView


#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect {
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();
	
	[self.rootLayer displayIfNeeded];
	
	[[self openGLContext] flushBuffer];
}


#pragma mark NSOpenGLView

- (void)prepareOpenGL {
	[super prepareOpenGL];
	
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	glEnable(GL_TEXTURE_2D);
	
	self.rootLayer = [[MALayer alloc] init];
	self.rootLayer.needsDisplayOnBoundsChange = YES;
}

- (void)reshape {
	[super reshape];
			
	glViewport(0, 0, (GLsizei) CGRectGetWidth(self.bounds), (GLsizei) CGRectGetHeight(self.bounds));
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	gluOrtho2D(0.0f, self.bounds.size.width, 0.0f, self.bounds.size.height);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	self.rootLayer.frame = NSRectToCGRect(self.bounds);
}


#pragma mark API

@synthesize rootLayer;

@end
