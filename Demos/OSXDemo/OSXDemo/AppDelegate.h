//
//  AppDelegate.h
//  OSXDemo
//
//  Created by Justin Spahr-Summers on 2011-09-11.
//  Released into the public domain.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSMutableArray *windowControllers;
@end
