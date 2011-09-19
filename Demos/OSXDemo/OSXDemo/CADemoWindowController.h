//
//  CADemoWindowController.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-17.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>
#import "DemoWindowController.h"

@class MAView;

@interface CADemoWindowController : DemoWindowController
@property (assign) IBOutlet MAView *contentView;
@end
