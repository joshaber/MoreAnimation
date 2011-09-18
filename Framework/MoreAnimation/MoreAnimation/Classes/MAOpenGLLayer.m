//
//  MAOpenGLLayer.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Released into the public domain.
//

#import "MAOpenGLLayer.h"
#import "MAOpenGLTexture.h"
#import "NSOpenGLContext+MoreAnimationExtensions.h"
#import <OpenGL/gl.h>

@interface MAOpenGLLayer ()
/**
 * The layer's #contents as an #MAOpenGLTexture. Any other type is disallowed.
 */
@property (strong, readonly) MAOpenGLTexture *contentsTexture;

/**
 * Draws the receiver into an empty texture in an OpenGL context, caching the
 * drawing into a new #contentsTexture.
 */
- (void)displayInGLContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat;

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
	// context; otherwise, do nothing
	MAOpenGLTexture *texture = self.contentsTexture;
	if (texture) {
		NSOpenGLContext *context = texture.GLContext;
		[self displayInGLContext:context pixelFormat:[context pixelFormat]];
	}
}

- (void)drawInContext:(CGContextRef)context {
  	// TODO
}

#pragma mark OpenGL drawing

- (void)displayInGLContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat; {
	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	size_t height = (size_t)ceil(size.height);

	[context executeWhileCurrentContext:^{
		CGContextRef bitmapContext = NULL;

		[self drawInGLContext:context pixelFormat:pixelFormat];

		// TODO: need to figure out how to render sublayers appropriately
		for (MALayer *sublayer in self.orderedSublayers) {
			if ([sublayer isKindOfClass:[MAOpenGLLayer class]]) {
				// TODO: transform matrix for the sublayer
				MAOpenGLLayer *sublayerGL = (MAOpenGLLayer *)sublayer;
				[sublayerGL renderInGLContext:context pixelFormat:pixelFormat];
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

				CGContextSaveGState(bitmapContext);

				CGAffineTransform affineTransform = [self affineTransformToLayer:sublayer];
				CGContextConcatCTM(bitmapContext, affineTransform);

				[sublayer renderInContext:bitmapContext];
				CGContextRestoreGState(bitmapContext);
			}
		}

		if (bitmapContext) {
			// TODO: how do we want to preserve GL sublayers when caching rendered
			// content like this?

			MAOpenGLTexture *texture = [MAOpenGLTexture textureWithGLContext:context];

			glBindTexture(GL_TEXTURE_2D, texture.textureID);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, CGBitmapContextGetData(bitmapContext));

			CGContextRelease(bitmapContext);

			self.contents = texture;
		}
	}];
}

- (void)drawInGLContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat; {
}

#pragma mark OpenGL rendering

- (void)renderInGLContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat; {
  	[self layoutIfNeeded];

  	[context executeWhileCurrentContext:^{
		MAOpenGLTexture *texture = self.contentsTexture;

		// captures the case of the texture being nil as well
		if (texture.GLContext != context || [self needsDisplay]) {
			// clear any existing texture
			self.contents = nil;

			// clear needsDisplay flag
			// TODO: this is kind of a hack
			[self display];

			// redisplay in the given context
			[self displayInGLContext:context pixelFormat:pixelFormat];
		}

		// render the existing or updated texture
		[self renderTexture:texture];
	}];
}

- (void)renderTexture:(MAOpenGLTexture *)texture {
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
}

@end
