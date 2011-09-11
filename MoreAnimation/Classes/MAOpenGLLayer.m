//
//  MAOpenGLLayer.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLLayer.h"
#import "MAOpenGLTexture.h"

@interface MAOpenGLLayer ()
@property (strong, readonly) MAOpenGLTexture *contentsTexture;
@end

@implementation MAOpenGLLayer
- (MAOpenGLTexture *)contentsTexture {
  	id contents = self.contents;
	NSAssert([contents isKindOfClass:[MAOpenGLTexture class]], @"MAOpenGLLayer contents should be an MAOpenGLTexture");

	return contents;
}

- (void)display {
  	// do nothing, since drawing is specific to the CGLContext being used
}

- (void)drawInCGLContext:(CGLContextObj)context pixelFormat:(CGLPixelFormatObj)pixelFormat {
}

- (void)renderInCGLContext:(CGLContextObj)context pixelFormat:(CGLPixelFormatObj)pixelFormat {
  	MAOpenGLTexture *texture = self.contentsTexture;
	if (!texture || texture.context != context) {
		[self drawInCGLContext:context pixelFormat:pixelFormat];
		return;
	}

	CGLLockContext(context);

	glBindTexture(GL_TEXTURE_2D, texture.textureID);
	glBegin(GL_QUADS);
	
	glTexCoord2f(0.0f, 0.0f);
	glVertex2f((GLfloat) self.frame.origin.x, (GLfloat) self.frame.origin.y);
	
	glTexCoord2f(1.0f, 0.0f);
	glVertex2f((GLfloat) self.frame.origin.x + (GLfloat) self.frame.size.width, (GLfloat) self.frame.origin.y);
	
	glTexCoord2f(1.0f, 1.0f);
	glVertex2f((GLfloat) self.frame.origin.x + (GLfloat) self.frame.size.width, (GLfloat) self.frame.origin.y + (GLfloat) self.frame.size.height);
	
	glTexCoord2f(0.0f, 1.0f);
	glVertex2f((GLfloat) self.frame.origin.x, (GLfloat) self.frame.origin.y + (GLfloat) self.frame.size.height);
	
	glEnd();
	CGLUnlockContext(context);
}

@end
