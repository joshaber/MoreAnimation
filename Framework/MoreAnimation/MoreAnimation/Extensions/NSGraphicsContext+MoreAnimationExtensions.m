//
//  NSGraphicsContext+MoreAnimationExtensions.m
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-19.
//  Released into the public domain.
//

#import "NSGraphicsContext+MoreAnimationExtensions.h"

@implementation NSGraphicsContext (MoreAnimationExtensions)
- (void)executeWhileCurrentContext:(dispatch_block_t)block {
  	NSGraphicsContext *previousContext = [NSGraphicsContext currentContext];
	[NSGraphicsContext setCurrentContext:self];

	block();

	[NSGraphicsContext setCurrentContext:previousContext];
}
@end
