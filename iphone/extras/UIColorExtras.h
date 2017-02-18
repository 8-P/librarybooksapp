#import <Foundation/Foundation.h>

@interface UIColor (UIColorExtras)

+ (UIColor *) colorWithHex: (NSUInteger) hexValue;
+ (UIColor *) colorWithHex: (NSUInteger) hexValue alpha: (CGFloat) alpha;

@end