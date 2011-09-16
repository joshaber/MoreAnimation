//
//  JAWindowController.h
//  WeakRefHater
//
//  Created by Josh Abernathy on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JAWindowController : NSWindowController

@property (nonatomic, readonly) id weakReferenceProxy;

@end
