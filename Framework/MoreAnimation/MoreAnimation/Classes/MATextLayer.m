//
//  MATextLayer.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-17.
//  Released into the public domain.
//

#import "MATextLayer.h"
#import "MALayer+Private.h"
#import "EXTScope.h"
#import <libkern/OSAtomic.h>

@interface MATextLayer () {
	/**
	 * Synchronizes access to this layer's properties.
	 */
	OSSpinLock m_spinLock;

	NSAttributedString *m_attributedString;
}

@end

@implementation MATextLayer

#pragma mark Properties

- (NSAttributedString *)attributedString {
  	OSSpinLockLock(&m_spinLock);
	@onExit {
		OSSpinLockUnlock(&m_spinLock);
	};

	return m_attributedString;
}

- (void)setAttributedString:(NSAttributedString *)str {
  	[self willChangeValueForKey:@"attributedString"];
	@onExit {
		[self didChangeValueForKey:@"attributedString"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_spinLock);
	if (![m_attributedString isEqual:str]) {
		m_attributedString = [str copy];
		changed = YES;
	}

	OSSpinLockUnlock(&m_spinLock);

	if (changed)
		[self setNeedsDisplay];
}

#pragma mark Drawing

- (void)display {
  	// only cache contents if this layer is opaque
  	if (self.opaque) {
		[super display];
	}
}

- (void)drawInContext:(CGContextRef)context {
	CGContextSetShouldAntialias(context, YES);
  	CGContextSetShouldSmoothFonts(context, YES);
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);

	CGMutablePathRef path = CGPathCreateMutable();
	@onExit {
		CGPathRelease(path);
	};

	CGPathAddRect(path, NULL, self.bounds);

	CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedString);
	@onExit {
		CFRelease(framesetter);
	};

	CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
	CTFrameDraw(frame, context);
}

@end
