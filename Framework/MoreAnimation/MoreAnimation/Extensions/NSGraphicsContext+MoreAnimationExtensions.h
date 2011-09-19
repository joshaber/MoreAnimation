//
//  NSGraphicsContext+MoreAnimationExtensions.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>

@interface NSGraphicsContext (MoreAnimationExtensions)
/**
 * Executes \a block while the receiver has set as the current thread's graphics
 * context. The previous context for the current thread is restored when
 * finished.
 */
- (void)executeWhileCurrentContext:(dispatch_block_t)block;
@end
