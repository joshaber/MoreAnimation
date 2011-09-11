//
//  MAOpenGLLayer.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLLayer.h"
#import "MAOpenGLTexture.h"
#import <OpenGL/gl.h>
//#import <OpenGL/glu.h>

@interface MAOpenGLLayer ()
/**
 * The layer's #contents as an #MAOpenGLTexture. Any other type is disallowed.
 */
@property (strong, readonly) MAOpenGLTexture *contentsTexture;

/**
 * Draws the receiver into an empty texture in \a CGLContext, caching the
 * drawing into a new #contentsTexture.
 */
- (void)displayInCGLContext:(CGLContextObj)CGLContext pixelFormat:(CGLPixelFormatObj)pixelFormat;

/**
 * Renders \a texture into its OpenGL context.
 */
- (void)renderTexture:(MAOpenGLTexture *)texture;
@end

@implementation MAOpenGLLayer

#pragma mark Properties

// inherited from superclass
@dynamic contents;

- (MAOpenGLTexture *)contentsTexture {
  	id contents = self.contents;
	NSAssert(!contents || [contents isKindOfClass:[MAOpenGLTexture class]], @"MAOpenGLLayer contents should be an MAOpenGLTexture");

	return contents;
}

#pragma mark MALayer overrides

- (void)display {
  	// if we have a texture, assume that we want to redisplay in the same
	// CGLContext; otherwise, do nothing
	if (self.contentsTexture) {
		CGLContextObj context = self.contentsTexture.CGLContext;
		[self displayInCGLContext:context pixelFormat:CGLGetPixelFormat(context)];
	}
}

- (void)drawInContext:(CGContextRef)context {
  	// TODO
}

#pragma mark OpenGL drawing

- (void)displayInCGLContext:(CGLContextObj)CGLContext pixelFormat:(CGLPixelFormatObj)pixelFormat {
  	CGContextRef bitmapContext = NULL;

	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	size_t height = (size_t)ceil(size.height);

	CGLLockContext(CGLContext);

	[self drawInCGLContext:CGLContext pixelFormat:pixelFormat];

	// TODO: need to figure out how to render sublayers appropriately
	for (MALayer *sublayer in [self.sublayers reverseObjectEnumerator]) {
		if ([sublayer isKindOfClass:[MAOpenGLLayer class]]) {
			// TODO: transform matrix for the sublayer
			MAOpenGLLayer *sublayerGL = (MAOpenGLLayer *)sublayer;
			[sublayerGL renderInCGLContext:CGLContext pixelFormat:pixelFormat];
		} else {
			if (!bitmapContext) {
				CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
				bitmapContext = CGBitmapContextCreate(
					NULL,
					width,
					height,
					8,
					4 * width,
					colorSpace,
					kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast
				);
				
				CGContextTranslateCTM(bitmapContext, 0, height);
				CGContextScaleCTM(bitmapContext, 1, -1);
				
				// Be sure to set a default fill color, otherwise CGContextSetFillColor behaves oddly (doesn't actually set the color?).
				CGColorRef defaultFillColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
				CGContextSetFillColorWithColor(bitmapContext, defaultFillColor);
				CGColorRelease(defaultFillColor);
				
				CGColorSpaceRelease(colorSpace);
			}

			[sublayer renderInContext:bitmapContext];
		}
	}

	if (bitmapContext) {
		// TODO: how do we want to preserve GL sublayers when caching rendered
		// content like this?
		
		MAOpenGLTexture *texture = [MAOpenGLTexture textureWithCGLContext:CGLContext];

		glBindTexture(GL_TEXTURE_2D, texture.textureID);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, CGBitmapContextGetData(bitmapContext));

		CGContextRelease(bitmapContext);

		self.contents = texture;
	}

	CGLUnlockContext(CGLContext);
}

- (void)drawInCGLContext:(CGLContextObj)CGLContext pixelFormat:(CGLPixelFormatObj)pixelFormat {
}

#pragma mark OpenGL rendering

- (void)renderInCGLContext:(CGLContextObj)CGLContext pixelFormat:(CGLPixelFormatObj)pixelFormat {
  	// captures the case of the texture being nil as well
	if (self.contentsTexture.CGLContext != CGLContext) {
		// clear any existing texture
		self.contents = nil;
		
		// clear needsDisplay flag
		// TODO: this is kind of a hack
		[self display];

		// redisplay in the given context
		[self displayInCGLContext:CGLContext pixelFormat:pixelFormat];
	}

	// render the existing or updated texture
	[self renderTexture:self.contentsTexture];
}

- (void)renderTexture:(MAOpenGLTexture *)texture {
	CGLLockContext(texture.CGLContext);
	glBindTexture(GL_TEXTURE_2D, texture.textureID);

	// draw a textured quad over the full frame of the layer
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

	CGLUnlockContext(texture.CGLContext);
}

@end
