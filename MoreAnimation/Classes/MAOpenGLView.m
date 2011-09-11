//
//  MAOpenGLView.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLView.h"
#import "MAOpenGLLayer.h"

@implementation MAOpenGLView


#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect {
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();

	CGLContextObj CGLContext = self.openGLContext.CGLContextObj;
	CGLPixelFormatObj CGLPixelFormat = self.pixelFormat.CGLPixelFormatObj;
	
	[self.contentLayer renderInCGLContext:CGLContext pixelFormat:CGLPixelFormat];
	
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
	
	self.contentLayer.frame = NSRectToCGRect(self.bounds);
}


#pragma mark API

@synthesize contentLayer;

@end
