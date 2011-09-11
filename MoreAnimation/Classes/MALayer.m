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
	id m_contents;

	dispatch_queue_t m_renderQueue;
}

- (void)displayChildren;
- (void)drawQuad;
- (void)generateTextureFromImage:(CGImageRef)image;

@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, strong) NSMutableArray *sublayers;
@property (readonly) CGImageRef contentsImage;
@property (readonly) CGLayerRef contentsLayer;

// publicly readonly
@property (nonatomic, readwrite, assign) BOOL needsDisplay;
@end


@implementation MALayer

- (id)init {
	self = [super init];
	if(self == nil) return nil;
	
	m_renderQueue = dispatch_queue_create("MoreAnimation.MALayer", DISPATCH_QUEUE_SERIAL);
	
	self.sublayers = [NSMutableArray array];
	self.needsDisplay = YES;
	
	return self;
}

#pragma mark API

- (id)contents {
  	__block id image = NULL;

	dispatch_sync(m_renderQueue, ^{
		image = m_contents;
	});

	return image;
}

- (CGImageRef)contentsImage {
  	CGImageRef obj = (__bridge CGImageRef)self.contents;
	CFTypeID typeID = CFGetTypeID(obj);

	if (typeID == CGImageGetTypeID())
		return obj;
	else
		return NULL;
}

- (CGLayerRef)contentsLayer {
  	CGLayerRef obj = (__bridge CGLayerRef)self.contents;
	CFTypeID typeID = CFGetTypeID(obj);

	if (typeID == CGLayerGetTypeID())
		return obj;
	else
		return NULL;
}

- (void)setContents:(id)contents {
	dispatch_async(m_renderQueue, ^{
		m_contents = contents;
	});
}

@synthesize textureId;
@synthesize frame;
@synthesize sublayers;
@synthesize delegate;
@synthesize needsDisplay;

- (void)dealloc {	
	glDeleteTextures(1, &textureId);
	dispatch_release(m_renderQueue);
}

- (void)display {
	CGSize size = self.bounds.size;
	size_t width = (size_t)ceil(size.width);
	size_t height = (size_t)ceil(size.height);

	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

	CGContextRef context = CGBitmapContextCreate(
		NULL,
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

	self.contents = (__bridge_transfer id)CGLayerCreateWithContext(context, size, NULL);
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);

	[self generateTextureFromImage:image];
	CGImageRelease(image);
}

- (void)displayIfNeeded {
  	if (!self.needsDisplay)
		return;
	
	if ([self.delegate respondsToSelector:@selector(displayLayer:)])
		[self.delegate displayLayer:self];
	else
		[self display];

  	self.needsDisplay = NO;
}

- (void)setNeedsDisplay {
  	self.needsDisplay = YES;
}

- (void)generateTextureFromImage:(CGImageRef)image {
	if(self.textureId == 0) {
		glGenTextures(1, &textureId);
	}

	glBindTexture(GL_TEXTURE_2D, self.textureId);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); 
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	size_t width = CGImageGetWidth(image);
	size_t height = CGImageGetHeight(image);

	void *textureData = (void *) malloc(width * height * 4);
		
	CGContextRef context = CGBitmapContextCreate(
		textureData,
		width,
		height,
		8,
		4 * width,
		CGImageGetColorSpace(image),
		kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast
	);

	CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
	CGContextRelease(context);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, textureData);
	free(textureData);

	[self drawQuad];
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

	CGImageRef image;
	CGLayerRef layer;

	if ((layer = self.contentsLayer))
		CGContextDrawLayerInRect(context, self.bounds, layer);
	else if ((image = self.contentsImage))
		CGContextDrawImage(context, self.bounds, image);
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
