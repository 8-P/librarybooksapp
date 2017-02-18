#import "TextEnabledTransformer.h"

@implementation TextEnabledTransformer

+ (Class) transformedValueClass;
{
	return [NSColor class];
}

+ (BOOL) allowsReverseTransformation;
{
	return YES;   
}

- (id) transformedValue: (id) value
{
	if (value == nil) return nil;
	
	if ([value boolValue] == TRUE)
	{
		return [NSColor controlTextColor];
	}
	else
	{
		return [NSColor lightGrayColor];
	}
}

@end