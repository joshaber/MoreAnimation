//
//  JAWindowController.m
//  WeakRefHater
//
//  Created by Josh Abernathy on 9/16/11.
//  Released into the public domain.
//

#import "JAWindowController.h"
#import "JAWeakReferenceHaterProxy.h"

@interface JAWindowController ()
@property (nonatomic, strong) JAWeakReferenceHaterProxy *internalWeakReferenceProxy;
@end


@implementation JAWindowController

- (void)dealloc {
	self.internalWeakReferenceProxy.weakReferenceHater = nil;
}


#pragma mark API

@synthesize internalWeakReferenceProxy;

- (JAWeakReferenceHaterProxy *)weakReferenceProxy {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		self.internalWeakReferenceProxy = [[JAWeakReferenceHaterProxy alloc] initWithWeakReferenceHater:self];
	});
	
	return internalWeakReferenceProxy;
}

@end
