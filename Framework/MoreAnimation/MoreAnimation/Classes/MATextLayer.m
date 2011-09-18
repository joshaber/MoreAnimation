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

	NSString *m_string;
	CGColorRef m_foregroundColor;
}

@end

@implementation MATextLayer

- (id)init {
  	if ((self = [super init])) {
		CGColorRef color = CGColorCreateGenericGray(1, 1);
		self.foregroundColor = color;
		CGColorRelease(color);
	}

	return self;
}

- (void)dealloc {
  	self.foregroundColor = NULL;
}

#pragma mark Properties

- (NSString *)string {
  	OSSpinLockLock(&m_spinLock);
	@onExit {
		OSSpinLockUnlock(&m_spinLock);
	};

	return m_string;
}

- (void)setString:(NSString *)str {
  	[self willChangeValueForKey:@"string"];
	@onExit {
		[self didChangeValueForKey:@"string"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_spinLock);
	if (![m_string isEqualToString:str]) {
		m_string = [str copy];
		changed = YES;
	}

	OSSpinLockUnlock(&m_spinLock);

	if (changed)
		[self setNeedsDisplay];
}

- (CGColorRef)foregroundColor {
  	OSSpinLockLock(&m_spinLock);
	@onExit {
		OSSpinLockUnlock(&m_spinLock);
	};

	return m_foregroundColor;
}

- (void)setForegroundColor:(CGColorRef)color {
  	[self willChangeValueForKey:@"foregroundColor"];
	@onExit {
		[self didChangeValueForKey:@"foregroundColor"];
	};

	BOOL changed = NO;

	OSSpinLockLock(&m_spinLock);
	if (!CGColorEqualToColor(m_foregroundColor, color)) {
		CGColorRelease(m_foregroundColor);
		m_foregroundColor = CGColorRetain(color);

		changed = YES;
	}

	OSSpinLockUnlock(&m_spinLock);

	if (changed)
		[self setNeedsDisplay];
}

#pragma mark Drawing

- (void)drawInContext:(CGContextRef)context {
	CGContextSetShouldAntialias(context, YES);
  	CGContextSetShouldSmoothFonts(context, YES);
	CGContextSetFillColorWithColor(context, self.foregroundColor);

	CGContextSelectFont(context, "Helvetica", 48, kCGEncodingMacRoman);

	NSString *str = self.string;
	CGContextShowTextAtPoint(context, 0, 0, [str UTF8String], [str length]);
}

@end
