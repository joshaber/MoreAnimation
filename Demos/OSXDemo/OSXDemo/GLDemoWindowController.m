//
//  GLDemoWindowController.m
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GLDemoWindowController.h"
#import <MoreAnimation/MoreAnimation.h>

static const CGPoint anchorArray[5] = {
	{1, 1} /*ThirdQuadrantAnchor*/,
	{1, 0} /*SecondQuadrantAnchor}*/,
	{0, 0} /*FirstQuadrantAnchor*/,
	{0, 1} /*FourthQuadrantAnchor*/,
	{0.5, 0.5} /*CenterAnchor*/
};

@interface GLDemoWindowController () <MALayerDelegate>
@property (nonatomic, assign) NSUInteger anchorIndex;
@property (nonatomic, strong) MALayer *prettyLayer;
@end

@implementation GLDemoWindowController
@synthesize anchorIndex = m_anchorIndex;
@synthesize prettyLayer = m_prettyLayer;
@synthesize openGLView = m_openGLView;

- (id)init {
  	return [self initWithWindowNibName:@"GLDemoWindow"];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	self.prettyLayer = [[MALayer alloc] init];
	self.prettyLayer.delegate = [self weakReferenceProxy];
	self.prettyLayer.frame = CGRectInset(self.openGLView.contentLayer.frame, 20, 20);
	[self.openGLView.contentLayer addSublayer:self.prettyLayer];

    self.anchorIndex = 0;
}

#pragma mark MALayerDelegate

- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context {
	NSImage *nsImage = [NSImage imageNamed:@"test"];
	CGContextDrawImage(context, layer.bounds, [nsImage CGImageForProposedRect:NULL context:NULL hints:nil]);

	CGContextSetFillColor(context, (CGFloat []) { 0.0f, 0.0f, 1.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(20.0f, 20.0f, 200.0f, 200.0f));

	CGContextSetFillColor(context, (CGFloat []) { 1.0f, 0.0f, 0.0f, 1.0f });
	CGContextFillRect(context, CGRectMake(70.0f, 70.0f, 100.0f, 100.0f));
}

#pragma mark Actions

- (IBAction)changeAnchorPoint:(id)sender {
    CGPoint oldAnchor = self.prettyLayer.anchorPoint;
    CGPoint newAnchor = anchorArray[self.anchorIndex % 5];
    self.anchorIndex++;
    self.openGLView.contentLayer.anchorPoint = newAnchor;
}

- (IBAction)flipABitch:(id)sender {
    CGSize size = self.openGLView.bounds.size;
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformScale(transform, -1, -1);

    self.prettyLayer.affineTransform = transform;
}

- (IBAction)flipDemTables:(id)sender {
    CGSize size = self.openGLView.bounds.size;
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformScale(transform, 1, -1);

    self.prettyLayer.affineTransform = transform;
}

- (IBAction)brotate:(id)sender {
    CGSize size = self.openGLView.bounds.size;
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformRotate(transform, M_PI_4/4);

    self.prettyLayer.affineTransform = transform;
}

- (IBAction)infinitizeLayers:(id)sender {
    MALayer *topLayer = self.prettyLayer;
    for (NSUInteger i = 0;i < 10000;++i) {
        MALayer *nextLayer = [[MALayer alloc] init];
        nextLayer.delegate = self;
        nextLayer.frame = CGRectInset(topLayer.bounds, 2, 2);
        [topLayer addSublayer:nextLayer];

        topLayer = nextLayer;
    }
}

- (IBAction)hugEveryCat:(id)sender {
    MALayer *topLayer = self.prettyLayer;
    
    CGFloat height = topLayer.frame.size.height / 10;
    for (NSUInteger i = 0;i < topLayer.frame.size.width/5;++i) {
        for(NSUInteger j = 0; j < 10; ++j) {
            MALayer *nextLayer = [[MALayer alloc] init];
            nextLayer.delegate = self;
            nextLayer.frame = CGRectMake(i * 5, height * j, 5, height);
            [topLayer addSublayer:nextLayer];
        }
    }
}


@end
