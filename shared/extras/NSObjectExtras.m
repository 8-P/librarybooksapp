#import "NSObjectExtras.h"

@implementation NSObject (NSObjectExtras)

- (id) objectAtPath: (NSString *) path
{
	NSArray *pathComponents = [path componentsSeparatedByString: @"/"];
	id object				= self;

	for (NSString *component in pathComponents)
	{
		// Skip empty path components produced by componentsSeparatedByString
		if ([component length] == 0) continue;
	
		if ([object isKindOfClass: [NSDictionary class]])
		{
			object = [object objectForKey: component];
		}
		else if ([object isKindOfClass: [NSArray class]])
		{
			NSInteger index = [component integerValue];
			object = (index < [object count]) ? [object objectAtIndex: index] : nil;
		}
		
		if (object == nil) return nil;
	}
	
	return object;
}

@end