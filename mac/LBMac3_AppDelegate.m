#import "LBMac3_AppDelegate.h"
#import "DataStore.h"
#import "Debug.h"

#ifndef APP_STORE
#import "PFMoveApplication.h"
#import "Sparkle.h"
#endif

@implementation LBMac3_AppDelegate

@synthesize window;

#ifndef APP_STORE
static Sparkle *sparkle;
#endif

- (void) applicationWillFinishLaunching: (NSNotification *) notification
{
	[window center];

	[Debug divider];
	[Debug log: @"LB launched, version [%@], date [%@]",
		[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"],
		[[NSDate date] description]
	];

#ifndef APP_STORE
	// If not in /Applications, offer to move it there
	PFMoveToApplicationsFolderIfNecessary();
	
	// Configure Sparkle
	sparkle = [[Sparkle alloc] init];
#endif
}

- (void) dealloc
{
    [window release];
    [super dealloc];
}

- (NSManagedObjectContext *) managedObjectContext
{
	return [[DataStore sharedDataStore] managedObjectContext];
}

@end