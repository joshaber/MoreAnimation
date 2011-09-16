//
//  AppDelegate.m
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "GLDemoWindowController.h"

@implementation AppDelegate

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	NSWindowController *firstController = [[GLDemoWindowController alloc] init];
	[firstController showWindow:self];
	[firstController becomeFirstResponder];

	self.windowControllers = [NSMutableArray arrayWithObject:firstController];
}

#pragma mark API

@synthesize windowControllers;

@end
