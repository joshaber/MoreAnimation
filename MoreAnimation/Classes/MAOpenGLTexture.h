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
@property (nonatomic, readonly) CGLContextObj CGLContext;

+ (id)textureWithCGLContext:(CGLContextObj)cxt;
+ (id)textureWithImage:(CGImageRef)image CGLContext:(CGLContextObj)cxt;
- (id)initWithCGLContext:(CGLContextObj)cxt;
- (id)initWithImage:(CGImageRef)image CGLContext:(CGLContextObj)cxt;
@end
