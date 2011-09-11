//
//  MAOpenGLTexture.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLTexture.h"

@interface MAOpenGLTexture () {
	CGLContextObj m_context;
}

@property (nonatomic, assign, readwrite) GLuint textureID;
@property (nonatomic, readwrite) CGLContextObj CGLContext;

- (id)initWithCGLContext:(CGLContextObj)cxt;
- (void)executeWhileLocked:(dispatch_block_t)block;
@end

@implementation MAOpenGLTexture
- (CGLContextObj)CGLContext {
  	return m_context;
}

- (void)setCGLContext:(CGLContextObj)cxt {
  	if (cxt != m_context) {
		if (m_context)
			CGLReleaseContext(m_context);
		
		if (cxt)
			CGLRetainContext(cxt);

		m_context = cxt;
	}
}

@synthesize textureID;

+ (id)textureWithCGLContext:(CGLContextObj)cxt {
	return [[self alloc] initWithCGLContext:cxt];
}

+ (id)textureWithImage:(CGImageRef)image CGLContext:(CGLContextObj)cxt {
	return [[self alloc] initWithImage:image CGLContext:cxt];
}

- (id)initWithCGLContext:(CGLContextObj)cxt {
  	if ((self = [super init])) {
		self.CGLContext = cxt;

		__block GLuint tex = 0;

		[self executeWhileLocked:^{
			glGenTextures(1, &tex);
		}];
		
		self.textureID = tex;
	}

	return self;
}

- (id)initWithImage:(CGImageRef)image CGLContext:(CGLContextObj)cxt {
  	if ((self = [self initWithCGLContext:cxt])) {
		size_t width = CGImageGetWidth(image);
		size_t height = CGImageGetHeight(image);
			
		CGContextRef context = CGBitmapContextCreate(
			NULL,
			width,
			height,
			8,
			4 * width,
			CGImageGetColorSpace(image),
			kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast
		);
		
		CGContextTranslateCTM(context, 0, height);
		CGContextScaleCTM(context, 1, -1);

		CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);

		[self executeWhileLocked:^{
			glBindTexture(GL_TEXTURE_2D, self.textureID);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, CGBitmapContextGetData(context));
		}];

		CGContextRelease(context);
	}

	return self;
}

- (void)dealloc {
  	GLuint tex = self.textureID;

  	[self executeWhileLocked:^{
		glDeleteTextures(1, &tex);
	}];

	self.textureID = 0;
	self.CGLContext = NULL;
}

- (void)executeWhileLocked:(dispatch_block_t)block {
  	CGLError error = CGLLockContext(self.CGLContext);
	if (error != 0) {
		// TODO: proper error handling!
		NSAssert(NO, @"error while locking CGL context");
	}

	block();
	CGLUnlockContext(self.CGLContext);
}

@end
