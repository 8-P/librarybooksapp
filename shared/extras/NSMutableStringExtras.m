#import "NSMutableStringExtras.h"

@implementation NSMutableString (NSMutableStringExtras)

// -----------------------------------------------------------------------------
//
// Do string replace.
//
// -----------------------------------------------------------------------------
- (unsigned int) replaceOccurrencesOfString: (NSString *) target withString: (NSString *) replacement
{
	return [self replaceOccurrencesOfString: target withString: replacement
		options: 0 range: NSMakeRange(0, [self length])];
}

@end