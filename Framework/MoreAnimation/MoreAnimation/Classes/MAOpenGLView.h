//
//  MAOpenGLView.h
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Released into the public domain.
//

#import <OpenGL/OpenGL.h>

@class MAOpenGLLayer;

/**
 * An \c NSOpenGLView that can display an #MAOpenGLLayer.
 */
@interface MAOpenGLView : NSOpenGLView
/**
 * The layer to display in the receiver.
 */
@property (nonatomic, strong) MAOpenGLLayer *contentLayer;
@end
