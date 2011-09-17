//
//  GLDemoWindowController.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DemoWindowController.h"

@class MAOpenGLView;

@interface GLDemoWindowController : DemoWindowController
@property (assign) IBOutlet MAOpenGLView *contentView;
@end
