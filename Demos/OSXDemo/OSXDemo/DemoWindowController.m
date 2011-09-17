//
//  DemoWindowController.m
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-16.
//  Released into the public domain.
//

#import "DemoWindowController.h"

static const CGPoint anchorArray[5] = {
	{1, 1} /*ThirdQuadrantAnchor*/,
	{1, 0} /*SecondQuadrantAnchor}*/,
	{0, 0} /*FirstQuadrantAnchor*/,
	{0, 1} /*FourthQuadrantAnchor*/,
	{0.5, 0.5} /*CenterAnchor*/
};

@interface DemoWindowController () <MALayerDelegate>
@property (nonatomic, assign) NSUInteger anchorIndex;
@end

@implementation DemoWindowController

#pragma mark Properties

@synthesize anchorIndex = m_anchorIndex;
@synthesize prettyLayer = m_prettyLayer;
@synthesize contentView = m_contentView;

#pragma mark Lifecycle

- (id)init {
  	NSString *className = NSStringFromClass([self class]);
	NSRange range = [className rangeOfString:@"Controller"];
	if (range.location == NSNotFound || range.location == 0)
		return [super init];
	else
		return [self initWithWindowNibName:[className substringToIndex:range.location]];
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
		[window useOptimizedDrawing:YES];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
	self.prettyLayer = [[MALayer alloc] init];
	self.prettyLayer.delegate = [self weakReferenceProxy];

	id layerView = self.contentView;
	self.prettyLayer.frame = CGRectInset([layerView contentLayer].frame, 20, 20);
	[[layerView contentLayer] addSublayer:self.prettyLayer];

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
    CGPoint newAnchor = anchorArray[self.anchorIndex % 5];
    self.anchorIndex++;
    self.prettyLayer.anchorPoint = newAnchor;
}

- (IBAction)flipABitch:(id)sender {
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformScale(transform, -1, -1);

    self.prettyLayer.affineTransform = transform;
}

- (IBAction)flipDemTables:(id)sender {
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformScale(transform, 1, -1);

    self.prettyLayer.affineTransform = transform;
}

- (IBAction)brotate:(id)sender {
    CGAffineTransform transform = self.prettyLayer.affineTransform;

    transform = CGAffineTransformRotate(transform, M_PI_4/4);

    self.prettyLayer.affineTransform = transform;
}

- (IBAction)infinitizeLayers:(id)sender {
    MALayer *topLayer = self.prettyLayer;
    for (NSUInteger i = 0;i < 10000;++i) {
        MALayer *nextLayer = [[MALayer alloc] init];
        nextLayer.delegate = [self weakReferenceProxy];
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
            nextLayer.delegate = [self weakReferenceProxy];
            nextLayer.frame = CGRectMake(i * 5, height * j, 5, height);
            [topLayer addSublayer:nextLayer];
        }
    }
}

@end
