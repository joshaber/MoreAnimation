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
@property (nonatomic, retain) CALayer *contentLayer;
@end

@implementation CADemoWindowController
@dynamic contentView;

- (void)windowDidLoad
{
    [super windowDidLoad];

	[self.contentView setLayer:[[CALayer alloc] init]];
	[self.contentView setWantsLayer:YES];
	[self.contentView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawDuringViewResize];
    
	// hack to verify interface compatibility with CALayer
	self.prettyLayer = (id)[[CALayer alloc] init];
	self.prettyLayer.delegate = [self weakReferenceProxy];
	self.prettyLayer.frame = CGRectInset(self.contentView.frame, 20, 20);
	[self.contentView.layer addSublayer:(id)self.prettyLayer];

	[self.contentView.layer setNeedsDisplay];
	[self.contentView setNeedsDisplay:YES];
}
@end

@implementation NSView (LayerExtensions)
- (CALayer *)contentLayer {
  	return nil;
}

- (void)setContentLayer:(CALayer *)layer {
}
@end
