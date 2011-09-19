//
//  JAWeakReferenceHaterProxy.m
//
//  Created by Josh Abernathy on 6/27/11.
//

#import "JAWeakReferenceHaterProxy.h"


@implementation JAWeakReferenceHaterProxy


#pragma mark NSProxy

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    return [self.weakReferenceHater methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	[invocation invokeWithTarget:self.weakReferenceHater];
}


#pragma mark API

@synthesize weakReferenceHater;

- (id)initWithWeakReferenceHater:(id)targetWeakReferenceHater {
	self.weakReferenceHater = targetWeakReferenceHater;
	return self;
}

@end
