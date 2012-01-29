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
- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context;
@end


@interface MALayer : NSObject

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, assign) BOOL needsDisplayOnBoundsChange;
@property (nonatomic, weak) id<MALayerDelegate> delegate;

- (void)drawInContext:(CGContextRef)context;

- (void)displayIfNeeded;
- (void)setNeedsDisplay;

@end
