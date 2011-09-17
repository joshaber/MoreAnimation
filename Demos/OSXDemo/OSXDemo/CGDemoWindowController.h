//
//  CGDemoWindowController.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>
#import "DemoWindowController.h"

@class MAView;

@interface CGDemoWindowController : DemoWindowController
@property (assign) IBOutlet MAView *contentView;
@end
