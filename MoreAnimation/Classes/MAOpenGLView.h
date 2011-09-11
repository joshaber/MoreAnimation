//
//  MAOpenGLView.h
//  MoreAnimation
//
//  Created by Josh Abernathy on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <OpenGL/OpenGL.h>

@class MAOpenGLLayer;


@interface MAOpenGLView : NSOpenGLView

@property (nonatomic, strong) MAOpenGLLayer *contentLayer;

@end
