#import "HTMLElement.h"
#import "SharedExtras.h"

@implementation HTMLElement

@synthesize name, value, attributes;
@dynamic scanner;

+ (HTMLElement *) element
{
	return [[[HTMLElement alloc] init] autorelease];
}

- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[name release];
	[value release];
	[attributes release];
	[scanner release];
	
	[super dealloc];
}

- (HTMLElement *) copyWithZone: (NSZone *) zone
{
    HTMLElement *copy	= [[HTMLElement allocWithZone: zone] init];
	copy->name			= [name copy];
	copy->value			= [value copy];
	copy->attributes	= [attributes copy];
	copy->scanner		= nil;

    return copy;
}

- (BOOL) hasAttribute: (NSString *) string
{
	for (NSString *attributeValue in [attributes allValues])
	{
		if ([attributeValue hasSubString: string])
		{
			return YES;
		}
	}
	
	return NO;
}

// -----------------------------------------------------------------------------
//
// Convienience method for return a scanner for parsing the value string.
//
// -----------------------------------------------------------------------------
- (NSScanner *) scanner
{
	if (scanner == nil)
	{
		scanner = [[NSScanner scannerWithString: value] retain];
	}
	
	return scanner;
}

@end