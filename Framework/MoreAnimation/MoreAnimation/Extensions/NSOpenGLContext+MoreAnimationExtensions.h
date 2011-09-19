//
//  NSOpenGLContext+MoreAnimationExtensions.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
//

#import <AppKit/AppKit.h>

@interface NSOpenGLContext (MoreAnimationExtensions)
/**
 * Obtains the pixel format of the receiver's associated \c CGLContextObj and
 * returns an \c NSOpenGLPixelFormat created from that object. Returns \c nil if
 * there was an error.
 */
- (NSOpenGLPixelFormat *)pixelFormat;

/**
 * Executes \a block while the receiver has been locked and set as the current
 * thread's OpenGL context.
 * 
 * @warning This method may block for an indefinite amount of time, if the
 * receiver's CGL context has been locked on another thread.
 */
- (void)executeWhileCurrentContext:(dispatch_block_t)block;
@end
