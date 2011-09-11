//
//  MALayer.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MALayer.h"
#import "MALayer+Private.h"
#import <libkern/OSAtomic.h>

@interface MALayer () {
	volatile CGImageRef m_contentsImage;
}

- (void)displayChildren;
- (void)drawQuad;

@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, strong) NSMutableArray *sublayers;

// publicly readonly
@property (nonatomic, readwrite, assign) BOOL needsDisplay;
@end


@implementation MALayer

- (id)init {
	self = [super init];
	if(self == nil) return nil;
	
	self.sublayers = [NSMutableArray array];
	self.needsDisplay = YES;
	
	return self;
}


#pragma mark API

- (id)contents {
  	return (__bridge id)m_contentsImage;
}

- (void)setContents:(id)contents {
  	CGImageRef newImage = (__bridge CGImageRef)contents;
	NSAssert(CFGetTypeID(newImage) == CGImageGetTypeID(), @"contents property only supports a CGImageRef");

	// atomically swap in the new contents
	CGImageRetain(newImage);

	CGImageRef oldImage = NULL;
	for (;;) {
		oldImage = m_contentsImage;
		if (OSAtomicCompareAndSwapPtrBarrier(oldImage, newImage, (void * volatile *)&m_contentsImage)) {
			CGImageRelease(oldImage);
		}
	}
}

@synthesize textureId;
@synthesize frame;
@synthesize sublayers;
@synthesize delegate;
@synthesize contents;
@synthesize needsDisplay;

- (void)dealloc {	
	glDeleteTextures(1, &textureId);
}

- (void)display {
	if(self.textureId == 0) {
		glGenTextures(1, &textureId);
	}
		
	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	size_t height = (size_t)ceil(size.height);

	glBindTexture(GL_TEXTURE_2D, self.textureId);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	void *textureData = (void *) malloc(width * height * 4);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

	CGContextRef context = CGBitmapContextCreate(
		textureData,
		width,
		height,
		8,
		4 * width,
		colorSpace,
		kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast
	);

	CGContextTranslateCTM(context, 0.0f, size.height);
	CGContextScaleCTM(context, 1.0f, -1.0f);
	
	// Be sure to set a default fill color, otherwise CGContextSetFillColor behaves oddly (doesn't actually set the color?).
	CGColorRef defaultFillColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetFillColorWithColor(context, defaultFillColor);
	CGColorRelease(defaultFillColor);

	CGColorSpaceRelease(colorSpace);

	if ([self.delegate respondsToSelector:@selector(drawLayer:inContext:)])
		[self.delegate drawLayer:self inContext:context];
	else
		[self drawInContext:context];
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, textureData);

	[self drawQuad];
	free(textureData);

	self.contents = (__bridge_transfer id)image;
  	self.needsDisplay = NO;
}

- (void)displayIfNeeded {
  	if (!self.needsDisplay)
		return;
	
	if ([self.delegate respondsToSelector:@selector(displayLayer:)])
		[self.delegate displayLayer:self];
	else
		[self display];
}

- (void)setNeedsDisplay {
  	self.needsDisplay = YES;
}

- (void)drawInContext:(CGContextRef)context {
	NSImage *nsImage = [NSImage imageNamed:@"test"];
	CGContextDrawImage(context, self.bounds, [nsImage CGImageForProposedRect:NULL context:NULL hints:nil]);
	
	CGContextSetFillColor(context, (CGFloat []) { 0.0f, 0.0f, 1.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(20.0f, 20.0f, 200.0f, 200.0f));
	
	CGContextSetFillColor(context, (CGFloat []) { 1.0f, 0.0f, 0.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(70.0f, 70.0f, 100.0f, 100.0f));
}

- (void)renderInContext:(CGContextRef)context {
  	[self displayIfNeeded];

	if (self.contents)
		CGContextDrawImage(context, self.bounds, (__bridge CGImageRef)self.contents);
	else
		[self drawInContext:context];
	
	for(MALayer *sublayer in [self.sublayers reverseObjectEnumerator]) {
		[sublayer renderInContext:context];
	}
}

- (void)displayRecursively {
	[self displayIfNeeded];
	[self displayChildren];
}

- (void)drawQuad {	
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

- (void)displayChildren {
	for(MALayer *sublayer in [self.sublayers reverseObjectEnumerator]) {
		[sublayer displayRecursively];
	}
}

- (CGRect)bounds {
	return CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

@end
