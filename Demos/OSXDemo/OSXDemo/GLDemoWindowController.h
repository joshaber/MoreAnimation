//
//  GLDemoWindowController.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>
#import "DemoWindowController.h"

@class MAOpenGLView;

@interface GLDemoWindowController : DemoWindowController
@property (assign) IBOutlet MAOpenGLView *contentView;
@end
