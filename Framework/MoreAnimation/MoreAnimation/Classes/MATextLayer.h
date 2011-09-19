//
//  MATextLayer.h
//  MoreAnimation
//
//  Created by Justin Spahr-Summers on 2011-09-17.
//  Released into the public domain.
//

#import "MALayer.h"

/**
 * A layer that renders a text string. Whenever possible, subpixel antialiasing
 * is enabled on the text.
 */
@interface MATextLayer : MALayer
/**
 * The string to render in this layer.
 */
@property (copy) NSAttributedString *attributedString;
@end
