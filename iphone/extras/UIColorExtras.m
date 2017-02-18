#import "UIColorExtras.h"

@implementation UIColor (UIColorExtras)

+ (UIColor *) colorWithHex: (NSUInteger) hexValue
{
	return [UIColor colorWithHex: hexValue alpha: 1];
}

+ (UIColor *) colorWithHex: (NSUInteger) hexValue alpha: (CGFloat) alpha
{
	CGFloat red		= ((hexValue & 0xFF0000) >> 16) / 255.0;
	CGFloat green	= ((hexValue &   0xFF00) >>  8) / 255.0;
	CGFloat blue	= ((hexValue &     0xFF)      ) / 255.0;
	
	return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

@end