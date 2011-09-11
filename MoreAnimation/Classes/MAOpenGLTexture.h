//
//  MAOpenGLTexture.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-10.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAOpenGLTexture : NSObject
@property (nonatomic, assign, readonly) GLuint textureID;
@property (nonatomic, readonly) CGLContextObj context;

+ (id)textureWithImage:(CGImageRef)image context:(CGLContextObj)cxt;
- (id)initWithImage:(CGImageRef)image context:(CGLContextObj)cxt;

/**
 * Locks the #context, binds the receiver's texture, then unlocks the #context.
 */
- (void)bind;
@end
