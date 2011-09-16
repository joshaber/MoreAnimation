//
//  MAOpenGLTexture.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLTexture.h"
#import "NSOpenGLContext+MoreAnimationExtensions.h"
#import <OpenGL/gl.h>

@interface MAOpenGLTexture ()
// publicly readonly
@property (nonatomic, assign, readwrite) GLuint textureID;
@property (nonatomic, strong, readwrite) NSOpenGLContext *GLContext;
@end

@implementation MAOpenGLTexture

#pragma mark Properties

@synthesize textureID = m_textureID;
@synthesize GLContext = m_GLContext;

#pragma mark Lifecycle

+ (id)textureWithGLContext:(NSOpenGLContext *)cxt {
	return [[self alloc] initWithGLContext:cxt];
}

+ (id)textureWithImage:(CGImageRef)image GLContext:(NSOpenGLContext *)cxt {
	return [[self alloc] initWithImage:image GLContext:cxt];
}

- (id)initWithGLContext:(NSOpenGLContext *)cxt {
  	if ((self = [super init])) {
		self.GLContext = cxt;

		__block GLuint tex = 0;

		[cxt executeWhileCurrentContext:^{
			glGenTextures(1, &tex);
		}];
		
		self.textureID = tex;
	}

	return self;
}

- (id)initWithImage:(CGImageRef)image GLContext:(NSOpenGLContext *)cxt {
  	if ((self = [self initWithGLContext:cxt])) {
		size_t width = CGImageGetWidth(image);
		size_t height = CGImageGetHeight(image);
			
		// create a bitmap context of a known format in which to draw the given
		// image
		CGContextRef context = CGBitmapContextCreate(
			NULL,
			width,
			height,
			8,
			4 * width,
			CGImageGetColorSpace(image),
			kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast
		);
		
		// flip the context vertically, since Core Graphics' origin is in the
		// lower-left, whereas texture data is expected to have an upper-left
		// origin
		CGContextTranslateCTM(context, 0, height);
		CGContextScaleCTM(context, 1, -1);

		CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

		[cxt executeWhileCurrentContext:^{
			glBindTexture(GL_TEXTURE_2D, self.textureID);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

			// copy the image data into our texture
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, CGBitmapContextGetData(context));
		}];

		CGContextRelease(context);
	}

	return self;
}

- (void)dealloc {
  	GLuint tex = self.textureID;

  	[self.GLContext executeWhileCurrentContext:^{
		glDeleteTextures(1, &tex);
	}];

	self.textureID = 0;
}

@end
