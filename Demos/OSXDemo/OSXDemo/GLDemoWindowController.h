//
//  GLDemoWindowController.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JAWindowController.h"

@class MAOpenGLView;

@interface GLDemoWindowController : JAWindowController
@property (assign) IBOutlet MAOpenGLView *openGLView;

- (id)init;
@end
