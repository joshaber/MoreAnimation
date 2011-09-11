//
//  MAOpenGLLayer.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MALayer.h"

@interface MAOpenGLLayer : MALayer
/**
 * The contents of the layer. Can be set to an #MAOpenGLTexture to display. No
 * other types are allowed on an MAOpenGLLayer.
 */
@property (strong) id contents;

- (void)drawInCGLContext:(CGLContextObj)context pixelFormat:(CGLPixelFormatObj)pixelFormat;
- (void)renderInCGLContext:(CGLContextObj)context pixelFormat:(CGLPixelFormatObj)pixelFormat;
@end
