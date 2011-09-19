//
//  MAOpenGLTexture.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Released into the public domain.
//

#import <Foundation/Foundation.h>

/**
 * A texture object that can be used for the contents of an #MAOpenGLLayer.
 */
@interface MAOpenGLTexture : NSObject
/**
 * The OpenGL texture ID associated with the receiver. This texture can be
 * freely modified and/or used for rendering.
 *
 * @warning When the receiver is deallocated, this texture ID will be deleted.
 */
@property (nonatomic, assign, readonly) GLuint textureID;

/**
 * The OpenGL context associated with the receiver. You should not attempt to
 * bind the receiver's #textureID in any other OpenGL context without first
 * copying the texture object into that context.
 */
@property (nonatomic, strong, readonly) NSOpenGLContext *GLContext;

/**
 * Returns an autoreleased texture initialized with #init.
 */
+ (id)texture;

/**
 * Returns an autoreleased texture initialized with #initWithGLContext:.
 */
+ (id)textureWithGLContext:(NSOpenGLContext *)cxt;

/**
 * Returns an autoreleased texture initialized with #initWithImage:GLContext:.
 */
+ (id)textureWithImage:(CGImageRef)image GLContext:(NSOpenGLContext *)cxt;

/**
 * Invokes #initWithGLContext: with the current \c NSOpenGLContext for the
 * current thread.
 */
- (id)init;

/**
 * Initializes a texture object with the specified OpenGL context. A #textureID
 * will be automatically created, and can be associated with any image data
 * desired.
 *
 * This is the designated initializer for this class.
 */
- (id)initWithGLContext:(NSOpenGLContext *)cxt;

/**
 * Initializes a texture object with the specified OpenGL context, using the
 * image data from \a image.
 */
- (id)initWithImage:(CGImageRef)image GLContext:(NSOpenGLContext *)cxt;
@end
