#import "LBTouchAppDelegate.h"
#import "DataStore.h"
#import "LibraryProperties.h"
#import "Debug.h"
#import "Settings.h"
#import "SharedExtras.h"
#import "UpdateManager.h"

@implementation LBTouchAppDelegate

@synthesize window, tabBarController, migrationView;

static void exceptionHandler(NSException *exception);

// -----------------------------------------------------------------------------

- (BOOL) application: (UIApplication *) application didFinishLaunchingWithOptions: (NSDictionary *) launchOptions
{
	NSSetUncaughtExceptionHandler(&exceptionHandler);

    // Add the tab bar controller's current view as a subview of the window
	
	// TODO: PHASE II - temporarily remove search functionality.  To be added
	// back in later
//	NSMutableArray *viewControllers = [[tabBarController.viewControllers mutableCopy] autorelease];
//	[viewControllers removeObjectAtIndex: 2];
//	tabBarController.viewControllers = viewControllers;
	
	if ([DataStore isMigrationNecessary])
	{
		[self migrateThenLoadMainApplication];
	}
	else
	{
		[self loadMainApplication];
	}
	
	return YES;
}

- (void) migrateThenLoadMainApplication
{
	[window addSubview: migrationView];
}

- (void) loadMainApplication
{
	// Setup tab bar
	tabBarController.delegate = self;
	[self restoreLastSelectedTab];
	[window addSubview: tabBarController.view];
	
	// Set up a observer to refresh the badge counts.  Also force the counts to
	// display initially
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadBadges:)
		name: @"BadgesNeedReloading" object: nil];
	[self reloadBadges: nil];

	[self autoUpdateCheck];
}

// -----------------------------------------------------------------------------
//
// This gets called when restoring a backgrounded app.
//
// -----------------------------------------------------------------------------
- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self autoUpdateCheck];
}

// -----------------------------------------------------------------------------
//
// Auto update on startup.
//
// -----------------------------------------------------------------------------
- (void) autoUpdateCheck
{
	Settings *settings = [Settings sharedSettings];
	if (settings.autoUpdate && settings.secondsSinceLastAutoUpdate >= 3600)
	{
		[[UpdateManager sharedUpdateManager] update];
	}
}

- (void) applicationWillTerminate: (UIApplication *) application
{
}

- (void) dealloc
{
    [tabBarController release];
    [window release];
    [super dealloc];
}

- (void) reloadBadges: (id) sender
{
	DataStore *dataStore = [DataStore sharedDataStore];
	Settings *settings = [Settings sharedSettings];

	// Loans
	int numberOverdue = [dataStore countOverdueLoans];
	UIViewController *viewController = [tabBarController.viewControllers objectAtIndex: 0];
	viewController.tabBarItem.badgeValue = (numberOverdue > 0) ? [NSString stringWithFormat: @"%d", numberOverdue] : nil;

	// Holds
	int numberReadyForPickup = [dataStore countReadyForPickupHolds];
	viewController = [tabBarController.viewControllers objectAtIndex: 1];
	viewController.tabBarItem.badgeValue = (numberReadyForPickup > 0) ? [NSString stringWithFormat: @"%d", numberReadyForPickup] : nil;
	
	int count = 0;
	if (settings.appBadge)
	{
		NSDate *date = [[NSDate today] dateByAddingDays: [settings.overdueAlertValue integerValue]];
		count = [dataStore countLoansDueBefore: date];
	}
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber: count];
}

- (void) tabBarController: (UITabBarController *) __tabBarController didSelectViewController: (UIViewController *) viewController
{
	// Save the selected tab so it can be restored when the app is restarted
	if (tabBarController.selectedIndex != NSNotFound)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger: tabBarController.selectedIndex forKey: @"lastSelectedTab"];
	}
}

// -----------------------------------------------------------------------------
//
// Restore the last selected tab.
//
// -----------------------------------------------------------------------------
- (void) restoreLastSelectedTab
{
	NSUserDefaults *defaults		= [NSUserDefaults standardUserDefaults];
	NSInteger lastSelectedTab		= [defaults integerForKey: @"lastSelectedTab"];
	NSUInteger numberTabBarItems	= [tabBarController.tabBar.items count];
	tabBarController.selectedIndex	= (lastSelectedTab < numberTabBarItems) ? lastSelectedTab : 0;
}

void exceptionHandler(NSException *exception)
{
    NSArray *stack = [exception callStackReturnAddresses];
	[Debug log: @"Exception - %@ - %@", [exception name], [exception reason]];
    [Debug logDetails: [[exception userInfo] description] withSummary: @"Exception - user info"];
	[Debug logDetails: [stack description] withSummary: @"Exception - stack"];
	[Debug saveLogToDisk];
}

@end