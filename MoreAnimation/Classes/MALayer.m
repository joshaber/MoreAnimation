//
//  MALayer.m
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MALayer.h"
#import "MALayer+Private.h"

@interface MALayer () {
	struct {
		unsigned int delegateDrawLayerInContext:1;
	} flags;
}

- (void)displaySelf;
- (void)displayChildren;
- (void)drawQuad;

@property (nonatomic, assign) GLuint textureId;
@property (nonatomic, assign) CGSize contextSize;
@property (nonatomic, strong) NSMutableArray *sublayers;
@property (nonatomic, assign) BOOL needsDisplay;
@end


@implementation MALayer

- (id)init {
	self = [super init];
	if(self == nil) return nil;
	
	self.sublayers = [NSMutableArray array];
	
	return self;
}


#pragma mark API

@synthesize textureId;
@synthesize frame;
@synthesize contextSize;
@synthesize sublayers;
@synthesize delegate;
@synthesize needsDisplay;
@synthesize needsDisplayOnBoundsChange;

- (void)dealloc {	
	glDeleteTextures(1, &textureId);
}

- (void)drawInContext:(CGContextRef)context {
	NSImage *nsImage = [NSImage imageNamed:@"test"];
	CGContextDrawImage(context, self.bounds, [nsImage CGImageForProposedRect:NULL context:NULL hints:nil]);
	
	CGContextSetFillColor(context, (CGFloat []) { 0.0f, 0.0f, 1.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(20.0f, 20.0f, 200.0f, 200.0f));
	
	CGContextSetFillColor(context, (CGFloat []) { 1.0f, 0.0f, 0.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(70.0f, 70.0f, 100.0f, 100.0f));
}

- (void)displayIfNeeded {
	if(!self.needsDisplay) return;
	
	[self displayRecursively];
	
	self.needsDisplay = NO;
}

- (void)displayRecursively {
	[self displaySelf];
	[self displayChildren];
}

- (void)displaySelf {
	if(self.textureId == 0) {
		glGenTextures(1, &textureId);
	}
		
	self.contextSize = self.bounds.size;
	
	glBindTexture(GL_TEXTURE_2D, self.textureId);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); 
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	void *textureData = (void *) malloc((size_t) (self.contextSize.width * self.contextSize.height * 4));
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef textureContext = CGBitmapContextCreate(textureData, (size_t) self.contextSize.width, (size_t) self.contextSize.height, 8, (size_t) self.contextSize.width * 4, colorSpace, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colorSpace);
	
	CGContextTranslateCTM(textureContext, 0.0f, self.contextSize.height);
	CGContextScaleCTM(textureContext, 1.0f, -1.0f);
	
	// Be sure to set a default fill color, otherwise CGContextSetFillColor behaves oddly (doesn't actually set the color?).
	CGColorRef defaultFillColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
	CGContextSetFillColorWithColor(textureContext, defaultFillColor);
	CGColorRelease(defaultFillColor);
	
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:textureContext flipped:YES]];
	
	if(flags.delegateDrawLayerInContext) {
		[self.delegate drawLayer:self inContext:textureContext];
	} else {
		[self drawInContext:textureContext];
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei) self.contextSize.width, (GLsizei) self.contextSize.height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8, textureData);
	
	[self drawQuad];
	
	CGContextRelease(textureContext);
	free(textureData);
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
		[sublayer displayIfNeeded];
	}
}

- (void)setNeedsDisplay {
	self.needsDisplay = YES;
}

- (void)setFrame:(CGRect)f {
	if(CGRectEqualToRect(frame, f)) return;
	
	frame = f;
	
	if(self.needsDisplayOnBoundsChange) {
		[self setNeedsDisplay];
	}
}

- (void)setDelegate:(id<MALayerDelegate>)d {
	if(delegate == d) return;
	
	delegate = d;
	
	flags.delegateDrawLayerInContext = (unsigned int) [self.delegate respondsToSelector:@selector(drawLayer:inContext:)];
}

- (CGRect)bounds {
	return CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

@end
