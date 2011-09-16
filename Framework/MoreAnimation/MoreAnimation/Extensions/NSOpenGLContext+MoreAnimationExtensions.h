//
//  NSOpenGLContext+MoreAnimationExtensions.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSOpenGLContext (MoreAnimationExtensions)
/**
 * Obtains the pixel format of the receiver's associated \c CGLContextObj and
 * returns an \c NSOpenGLPixelFormat created from that object. Returns \c nil if
 * there was an error.
 */
- (NSOpenGLPixelFormat *)pixelFormat;
@end
