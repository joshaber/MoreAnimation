//
//  DemoWindowController.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>
#import <MoreAnimation/MoreAnimation.h>
#import "JAWindowController.h"

/**
 * An abstract superclass for all demo window controllers.
 */
@interface DemoWindowController : JAWindowController
@property (assign) IBOutlet NSView *contentView;
@property (nonatomic, strong) MALayer *prettyLayer;

/**
 * Initializes this window controller with a nib based on the class name (minus
 * the "Controller" part).
 */
- (id)init;
@end
