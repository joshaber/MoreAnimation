//
//  MAOpenGLTexture.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MAOpenGLTexture.h"

@interface MAOpenGLTexture ()
@property (nonatomic, assign, readwrite) GLuint textureID;
@end

@implementation MAOpenGLTexture
@synthesize textureID;

+ (id)textureWithImage:(CGImageRef)image {
	return [[self alloc] initWithImage:image];
}

- (id)init {
  	if ((self = [super init])) {
		GLuint tex = 0;
		glGenTextures(1, &tex);
		
		self.textureID = tex;
	}

	return self;
}

- (id)initWithImage:(CGImageRef)image {
  	if ((self = [self init])) {
		glBindTexture(GL_TEXTURE_2D, self.textureID);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

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

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, CGBitmapContextGetData(context));

		CGContextRelease(context);
	}

	return self;
}

- (void)dealloc {
  	GLuint tex = self.textureID;
  	glDeleteTextures(1, &tex);

	self.textureID = 0;
}

@end
