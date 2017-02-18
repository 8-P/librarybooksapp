#import "Settings.h"

@implementation Settings

@synthesize overdueAlertProperties;
@dynamic overdueAlertTitle, overdueAlertValue, bookCovers, autoUpdate, secondsSinceLastAutoUpdate,
	overdueNotification, appBadge;

- (id) init
{
	self = [super init];

	defaults = [[NSUserDefaults standardUserDefaults] retain];

	[self initBookCovers];
	[self initAutoUpdate];
	[self initOverdueAlert];
	[self initOverdueNotification];
	[self initAppBadge];

	return self;
}

// =============================================================================
#pragma mark -
#pragma mark Overdue alert

- (void) initOverdueAlert
{
	NSString *path			= [[NSBundle mainBundle] pathForResource: @"OverdueWarningSettings" ofType: @"plist"];
	overdueAlertProperties	= [[NSDictionary dictionaryWithContentsOfFile: path] retain];
	
	NSString *key = [overdueAlertProperties objectForKey: @"Key"];
	id value = [defaults objectForKey: key];
	if (value == nil) [defaults setObject: [overdueAlertProperties objectForKey: @"DefaultValue"] forKey: key];
}

- (NSString *) overdueAlertTitle
{
	NSArray *values = [overdueAlertProperties objectForKey: @"Values"];
	NSNumber *value = self.overdueAlertValue;
	for (int i = 0; i < [values count]; i++)
	{
		if ([[values objectAtIndex: i] isEqual: value])
		{
			return [[overdueAlertProperties objectForKey: @"Titles"] objectAtIndex: i];
		}
	}
	
	return nil;
}

- (NSNumber *) overdueAlertValue
{
	return [defaults objectForKey: [overdueAlertProperties objectForKey: @"Key"]];
}

// =============================================================================
#pragma mark -
#pragma mark Book covers

- (void) initBookCovers
{
	id value = [defaults objectForKey: @"BookCovers"];
	if (value == nil) [defaults setObject: [NSNumber numberWithBool: YES] forKey: @"BookCovers"];
}

- (BOOL) bookCovers
{
	return [[defaults objectForKey: @"BookCovers"] boolValue];
}

- (void) setBookCovers: (BOOL) enabled
{
	[defaults setObject: [NSNumber numberWithBool: enabled] forKey: @"BookCovers"];
	[defaults synchronize];
}

// =============================================================================
#pragma mark -
#pragma mark Auto update

- (void) initAutoUpdate
{
	id value = [defaults objectForKey: @"AutoUpdate"];
	if (value == nil) [defaults setObject: [NSNumber numberWithBool: NO] forKey: @"AutoUpdate"];
	
	value = [defaults objectForKey: @"LastAutoUpdate"];
	if (value == nil) [defaults setObject: [NSDate distantPast] forKey: @"LastAutoUpdate"];
}

- (BOOL) autoUpdate
{
	return [[defaults objectForKey: @"AutoUpdate"] boolValue];
}

- (void) setAutoUpdate: (BOOL) enabled
{
	[defaults setObject: [NSNumber numberWithBool: enabled] forKey: @"AutoUpdate"];
	[defaults synchronize];
}

- (NSTimeInterval) secondsSinceLastAutoUpdate
{
	NSDate *lastAutoUpdate = [defaults objectForKey: @"LastAutoUpdate"];
	return -1 * [lastAutoUpdate timeIntervalSinceNow];
}

- (void) setLastAutoUpdateToNow
{
	[defaults setObject: [NSDate date] forKey: @"LastAutoUpdate"];
	[defaults synchronize];
}

// =============================================================================
#pragma mark -
#pragma mark Overdue Notification

- (void) initOverdueNotification
{
	id value = [defaults objectForKey: @"OverdueNotification"];
	if (value == nil) [defaults setObject: [NSNumber numberWithBool: YES] forKey: @"OverdueNotification"];
}

- (BOOL) overdueNotification
{
	return [[defaults objectForKey: @"OverdueNotification"] boolValue];
}

- (void) setOverdueNotification: (BOOL) enabled
{
	[defaults setObject: [NSNumber numberWithBool: enabled] forKey: @"OverdueNotification"];
	[defaults synchronize];
}

// =============================================================================
#pragma mark -
#pragma mark App Badge

- (void) initAppBadge
{
	id value = [defaults objectForKey: @"AppBadge"];
	if (value == nil) [defaults setObject: [NSNumber numberWithBool: YES] forKey: @"AppBadge"];
}

- (BOOL) appBadge
{
	return [[defaults objectForKey: @"AppBadge"] boolValue];
}

- (void) setAppBadge: (BOOL) enabled
{
	[defaults setObject: [NSNumber numberWithBool: enabled] forKey: @"AppBadge"];
	[defaults synchronize];
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static Settings *sharedSettings = nil;

+ (Settings *) sharedSettings
{
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            sharedSettings = [[Settings alloc] init];
        }
    }
	
    return sharedSettings;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedSettings;
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