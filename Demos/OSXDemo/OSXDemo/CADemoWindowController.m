//
//  CADemoWindowController.m
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-17.
//  Released into the public domain.
//

#import "CADemoWindowController.h"

@interface CADemoWindowController () <MALayerDelegate>
@end

@interface NSView (LayerExtensions)
@property (nonatomic, retain) MALayer *contentLayer;
@end

@implementation CADemoWindowController
@dynamic contentView;

- (void)windowDidLoad
{
	MAHostingCALayer *hostingLayer = [[MAHostingCALayer alloc] init];

	[self.contentView setLayer:hostingLayer];
	[self.contentView setWantsLayer:YES];
	[self.contentView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];

	self.contentView.contentLayer = [[MALayer alloc] init];
	self.contentView.contentLayer.frame = NSRectToCGRect(self.contentView.bounds);
    [super windowDidLoad];
}
@end

@implementation NSView (LayerExtensions)
- (MALayer *)contentLayer {
  	return [(id)self.layer MALayer];
}

- (void)setContentLayer:(MALayer *)layer {
  	[(id)self.layer setMALayer:layer];
}
@end
