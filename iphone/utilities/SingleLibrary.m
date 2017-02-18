#import "SingleLibrary.h"

@implementation SingleLibrary

@synthesize enabled, name, identifier, themeColour;

- (id) init
{
	self = [super init];

	NSString *path		= [[NSBundle mainBundle] pathForResource: @"SingleLibrary" ofType: @"plist"];
	NSDictionary *plist	= [NSDictionary dictionaryWithContentsOfFile: path];
	
	self.enabled = [[plist objectForKey: @"Enabled"] boolValue];
	if (self.enabled)
	{
		self.name		=  [plist objectForKey: @"Name"];
		self.identifier	=  [plist objectForKey: @"Identifier"];
		
		NSScanner *scanner = [NSScanner scannerWithString: [plist objectForKey: @"ThemeColour"]];
		NSUInteger colour;
		[scanner scanHexInt: &colour];
		self.themeColour = colour;
	}
	
	return self;
}

- (BOOL) isIdentifierEnabled: (NSString *) compareIdentifier
{
	return (self.enabled == NO || [self.identifier isEqualToString: compareIdentifier] || [compareIdentifier isEqualToString: @"test.TestLibrary"]);
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static SingleLibrary *sharedSingleLibrary = nil;

+ (SingleLibrary *) sharedSingleLibrary
{
    @synchronized(self)
	{
        if (sharedSingleLibrary == nil)
		{
            sharedSingleLibrary = [[SingleLibrary alloc] init];
        }
    }
	
    return sharedSingleLibrary;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedSingleLibrary == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedSingleLibrary;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (unsigned) retainCount
{
	// Denotes an object that cannot be released
    return UINT_MAX;
}

- (oneway void) release
{
    // Do nothing
}

- (id) autorelease
{
    return self;
}

@end