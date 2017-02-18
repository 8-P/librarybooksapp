#import "Preferences.h"

@implementation Preferences

@dynamic dueSoonWarningDays;

- (id) init
{
	self = [super init];

	defaults = [[NSUserDefaults standardUserDefaults] retain];

	return self;
}

- (NSInteger) dueSoonWarningDays
{
	NSInteger days = [defaults integerForKey: @"DueSoonWarningDays"];
	if (days == 8) days = 14;
	
	return days;
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static Preferences *sharedPreferences = nil;

+ (Preferences *) sharedPreferences
{
    @synchronized(self)
	{
        if (sharedPreferences == nil)
		{
            sharedPreferences = [[Preferences alloc] init];
        }
    }
	
    return sharedPreferences;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedPreferences == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedPreferences;
}

- (id) copyWithZone: (NSZone *) zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
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