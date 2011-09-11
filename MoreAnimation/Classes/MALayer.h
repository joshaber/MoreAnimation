//
//  MALayer.h
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MALayer;

@protocol MALayerDelegate <NSObject>
@optional
- (void)displayLayer:(MALayer *)layer;
- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context;
@end


@interface MALayer : NSObject

- (void)display;
- (void)displayIfNeeded;
- (void)drawInContext:(CGContextRef)context;
- (void)renderInContext:(CGContextRef)context;
- (void)setNeedsDisplay;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, weak) id<MALayerDelegate> delegate;

/**
 * The contents of the layer. Can be set to a \c CGImageRef to display. If not
 * explicitly set, the layer may store its own cached contents here in an
 * unspecified format (i.e., you cannot depend on this being a \c CGImageRef).
 */
@property (strong) id contents;

@property (nonatomic, readonly, strong) NSMutableArray *sublayers;
@property (nonatomic, readonly, assign) BOOL needsDisplay;

@end
