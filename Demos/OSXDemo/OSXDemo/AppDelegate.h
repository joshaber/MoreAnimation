//
//  AppDelegate.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MAOpenGLView;


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet MAOpenGLView *openGLView;
@property (weak) IBOutlet NSMenuItem *changeAnchorMenuItem;


@end
