//
//  NSOpenGLContext+MoreAnimationExtensions.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSOpenGLContext+MoreAnimationExtensions.h"
#import "EXTSafeCategory.h"

@safecategory (NSOpenGLContext, MoreAnimationExtensions)
- (NSOpenGLPixelFormat *)pixelFormat {
  	CGLContextObj context = CGLRetainContext([self CGLContextObj]);
	CGLPixelFormatObj pixelFormat = CGLRetainPixelFormat(CGLGetPixelFormat(context));
	CGLReleaseContext(context);

	NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithCGLPixelFormatObj:pixelFormat];
	CGLReleasePixelFormat(pixelFormat);

	return format;
}
@end
