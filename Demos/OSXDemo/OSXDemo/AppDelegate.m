//
//  AppDelegate.m
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "GLDemoWindowController.h"
#import "CGDemoWindowController.h"

@implementation AppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	self.windowControllers = [NSMutableArray arrayWithObjects:
		[[CGDemoWindowController alloc] init],
		nil
	];

	[self.windowControllers enumerateObjectsUsingBlock:^(NSWindowController *controller, NSUInteger index, BOOL *stop){
		[controller showWindow:self];
	}];

	[[self.windowControllers objectAtIndex:0] becomeFirstResponder];
}

#pragma mark API

@synthesize windowControllers;

@end
