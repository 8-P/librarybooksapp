// =============================================================================
//
// Manages the updating of loans and holds.
//
// Controls:
//		* The animation of the refresh buttons.
//		* Checks for Internet connectivity.
//
// =============================================================================

#import "UpdateManager.h"
#import "Reachability.h"
#import "Notifications.h"
#import "Settings.h"

@implementation UpdateManager

@synthesize updating;

- (id) init
{
	self = [super init];
	dataStore = [[DataStore sharedDataStore] retain];
	
	return self;
}

- (void) dealloc
{
	[dataStore release];
	[super dealloc];
}

- (void) update
{
	// Don't run more than 1 update thread at a time
	if (updating == YES) return;

	// Warn and give up if there is no network connection
	if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable)
	{
		UIAlertView *alert	= [[[UIAlertView alloc] init] autorelease];
		alert.message		= @"Cannot update because there is no Internet connection";
		alert.delegate		= self;
		
		[alert addButtonWithTitle: @"OK"];
		[alert show];
	
		return;
	}
	
	updating = YES;
	
	// Signal the start of the update
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateBegin" object: self];
	
	[NSThread detachNewThreadSelector: @selector(updateThread:) toTarget: self withObject: nil];
}

- (void) resendNotifications
{
	if (updating)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateBegin" object: self];
	}
	else 
	{
		[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateEnd" object: self];
	}

}

- (void) updateThread: (id) sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// Disable "idle sleep" as some libraries can take a while to update
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	// Do the update
	[dataStore update];
	
	[UIApplication sharedApplication].idleTimerDisabled = NO;
	updating = NO;
	
	Notifications *notifications = [Notifications notifications];
	[notifications update];
	
	[[Settings sharedSettings] setLastAutoUpdateToNow];
	
	// Signal the end of the update
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"UpdateEnd" object: self];

	[pool release];
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static UpdateManager *sharedUpdateManager = nil;

+ (UpdateManager *) sharedUpdateManager
{
    @synchronized(self)
	{
        if (sharedUpdateManager == nil)
		{
            sharedUpdateManager = [[UpdateManager alloc] init];
        }
    }
	
    return sharedUpdateManager;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedUpdateManager == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedUpdateManager;
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