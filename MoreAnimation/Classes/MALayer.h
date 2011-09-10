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
- (void)drawLayer:(MALayer *)layer inContext:(CGContextRef)context;
@end


@interface MALayer : NSObject

- (void)drawInContext:(CGContextRef)context;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, weak) id<MALayerDelegate> delegate;

@end
