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
@property (nonatomic, readwrite) CGLContextObj context;

- (id)initWithContext:(CGLContextObj)cxt;
- (void)executeWhileLocked:(dispatch_block_t)block;
@end

@implementation MAOpenGLTexture
- (CGLContextObj)context {
  	return m_context;
}

- (void)setContext:(CGLContextObj)cxt {
  	if (cxt != m_context) {
		if (m_context)
			CGLReleaseContext(m_context);
		
		if (cxt)
			CGLRetainContext(cxt);

		m_context = cxt;
	}
}

@synthesize textureID;

+ (id)textureWithImage:(CGImageRef)image context:(CGLContextObj)cxt {
	return [[self alloc] initWithImage:image context:cxt];
}

- (id)initWithContext:(CGLContextObj)cxt {
  	if ((self = [super init])) {
		self.context = cxt;

		__block GLuint tex = 0;

		[self executeWhileLocked:^{
			glGenTextures(1, &tex);
		}];
		
		self.textureID = tex;
	}

	return self;
}

- (id)initWithImage:(CGImageRef)image context:(CGLContextObj)cxt {
  	if ((self = [self initWithContext:cxt])) {
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
	self.context = NULL;
}

- (void)bind {
  	[self executeWhileLocked:^{
		glBindTexture(GL_TEXTURE_2D, self.textureID);
	}];
}

- (void)executeWhileLocked:(dispatch_block_t)block {
  	CGLError error = CGLLockContext(self.context);
	if (error != 0) {
		// TODO: proper error handling!
		NSAssert(NO, @"error while locking CGL context");
	}

	block();
	CGLUnlockContext(self.context);
}

@end
