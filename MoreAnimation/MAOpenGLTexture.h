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

+ (id)textureWithImage:(CGImageRef)image;
- (id)initWithImage:(CGImageRef)image;
@end
