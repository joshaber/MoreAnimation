//
//  MAHostingCALayer.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-29.
//  Copyright (c) 2011 Übermind, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@class MALayer;

/**
 * A Core Animation layer that hosts a More Animation layer tree.
 */
@interface MAHostingCALayer : CALayer
/**
 * The More Animation layer tree to display. The layer will be set to fill the
 * entire bounds of the receiver.
 * 
 * Most non-geometrical Core Animation properties accessed on the receiver will
 * simply call through to the properties on this layer.
 * 
 * @note This will override the MALayer#needsRenderBlock of any set layer. You
 * should not attempt to change the block set.
 */
@property (strong) MALayer *MALayer;
@end
