//
//  AppDelegate.m
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <MoreAnimation/MoreAnimation.h>

CGPoint anchorArray[5] = { {1, 1}/*ThirdQuadrantAnchor*/, {1, 0}/*SecondQuadrantAnchor}*/, {0, 0}/*FirstQuadrantAnchor*/, {0, 1}/*FourthQuadrantAnchor*/, {0.5, 0.5} /*CenterAnchor*/};

@interface AppDelegate () <MALayerDelegate> {
    NSUInteger anchorIndex;
}

@property (nonatomic, strong) MALayer *prettyLayer;
@end


@implementation AppDelegate


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	self.prettyLayer = [[MALayer alloc] init];
	self.prettyLayer.delegate = self;
	self.prettyLayer.frame = CGRectInset(self.openGLView.contentLayer.frame, 20, 20);
	[self.openGLView.contentLayer addSublayer:self.prettyLayer];

    anchorIndex = 0;

	[self.openGLView setNeedsDisplay:YES];
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


#pragma mark API

@synthesize window;
@synthesize openGLView;
@synthesize changeAnchorMenuItem;
@synthesize prettyLayer;

#pragma mark Actions
- (IBAction)changeAnchorPoint:(id)sender {
    CGPoint oldAnchor = self.prettyLayer.anchorPoint;
    CGPoint newAnchor = anchorArray[anchorIndex % 5];
    anchorIndex++;
    self.openGLView.contentLayer.anchorPoint = newAnchor;
    [self.openGLView setNeedsDisplay:YES];
}

- (IBAction)flipABitch:(id)sender {
    CGSize size = self.openGLView.bounds.size;
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformScale(transform, -1, -1);

    self.prettyLayer.affineTransform = transform;
    [self.prettyLayer setNeedsDisplay];
    [self.openGLView.contentLayer setNeedsDisplay];
    [self.openGLView setNeedsDisplay:YES];
}

- (IBAction)flipDemTables:(id)sender {
    CGSize size = self.openGLView.bounds.size;
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformScale(transform, 1, -1);

    self.prettyLayer.affineTransform = transform;
    [self.prettyLayer setNeedsDisplay];
    [self.openGLView.contentLayer setNeedsDisplay];
    [self.openGLView setNeedsDisplay:YES];
}
- (IBAction)brotate:(id)sender {
    CGSize size = self.openGLView.bounds.size;
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformRotate(transform, M_PI_4/4);

    self.prettyLayer.affineTransform = transform;
    [self.prettyLayer setNeedsDisplay];
    [self.openGLView.contentLayer setNeedsDisplay];
    [self.openGLView setNeedsDisplay:YES];
}
- (IBAction)infinitizeLayers:(id)sender {
    MALayer *topLayer = self.prettyLayer;
    for (NSUInteger i = 0;i < 10000;++i) {
        MALayer *nextLayer = [[MALayer alloc] init];
        nextLayer.delegate = self;
        nextLayer.frame = CGRectInset(topLayer.bounds, 2, 2);
        [topLayer addSublayer:nextLayer];
        [topLayer setNeedsDisplay];

        topLayer = nextLayer;
    }

    [self.openGLView.contentLayer setNeedsDisplay];
    [self.openGLView setNeedsDisplay:YES];
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
            [topLayer setNeedsDisplay];
        }
    }

    [self.openGLView.contentLayer setNeedsDisplay];
    [self.openGLView setNeedsDisplay:YES];
}

@end
