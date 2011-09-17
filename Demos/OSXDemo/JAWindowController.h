//
//  JAWindowController.h
//  WeakRefHater
//
//  Created by Josh Abernathy on 9/16/11.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>


@interface JAWindowController : NSWindowController

@property (nonatomic, readonly) id weakReferenceProxy;

@end
