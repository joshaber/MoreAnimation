//
//  MAOpenGLLayer.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MALayer.h"

/**
 * A layer for rendering OpenGL content. An OpenGL layer can host any other kind
 * of layer. Adding an OpenGL layer to any other layer type may incur
 * a significant performance penalty.
 */
@interface MAOpenGLLayer : MALayer
/**
 * The contents of the layer. Can be set to an #MAOpenGLTexture to display. No
 * other types are allowed on an MAOpenGLLayer.
 */
@property (strong) id contents;

/**
 * Draws a single frame into the provided OpenGL context, which is of the
 * specified pixel format. The default implementation does nothing.
 *
 * This method does not draw sublayers.
 */
- (void)drawInCGLContext:(CGLContextObj)context pixelFormat:(CGLPixelFormatObj)pixelFormat;

/**
 * Renders a cached representation of the receiver into the provided OpenGL
 * context, which is of the specified pixel format.
 */
- (void)renderInCGLContext:(CGLContextObj)context pixelFormat:(CGLPixelFormatObj)pixelFormat;
@end
