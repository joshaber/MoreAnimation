//
//  JAWeakReferenceHaterProxy.h
//
//  Created by Josh Abernathy on 6/27/11.
//

#import <Foundation/Foundation.h>

@class GHViewController;


@interface JAWeakReferenceHaterProxy : NSProxy

@property (nonatomic, unsafe_unretained) id weakReferenceHater;

- (id)initWithWeakReferenceHater:(id)targetWeakReferenceHater;

@end
