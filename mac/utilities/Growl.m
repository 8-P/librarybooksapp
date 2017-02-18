#import "Growl.h"
#import "Debug.h"
#import "DataStore.h"
#import "SharedExtras.h"

@implementation Growl

#define OVERDUE_LOANS_NOTIFICATION	@"Overdue Loans"
#define HOLDS_READY_NOTIFICATION	@"Holds Ready For Pickup"

- (id) init
{
	self = [super init];
	[GrowlApplicationBridge setGrowlDelegate: self];
	
	return self;
}

- (void) update
{
	[Debug log: @"Updating Growl"];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *lastTimeGrowlDisplay = [defaults objectForKey: @"LastGrowlDisplayTime"];
	if (lastTimeGrowlDisplay && [lastTimeGrowlDisplay isToday])
	{
		// Don't display the Growl alert if it has already been displayed today
		return;
	}
	
	DataStore *dataStore = [DataStore sharedDataStore];
	
	// Overdue loans
	NSInteger count = [dataStore countOverdueLoans];
	if (count > 0)
	{
		NSString *message = (count == 1)
			? @"You have 1 due/overdue loan"
			: [NSString stringWithFormat: @"You have %ld due/overdue loans", (long) count];
		[self displayOverdueLoanMessage: message title: @"Library Books"];
	}
	
	// Holds ready for pickup
	count = [dataStore countReadyForPickupHolds];
	if (count > 0)
	{
		NSString *message = (count == 1)
			? @"You have 1 hold ready for pickup"
			: [NSString stringWithFormat: @"You have %ld holds ready for pickup", (long) count];
		[self displayHoldsReadyMessage: message title: @"Library Books"];
	}
	
	[defaults setObject: [NSDate today] forKey: @"LastGrowlDisplayTime"];
}

- (void) displayOverdueLoanMessage: (NSString *) message title: (NSString *) title
{
	if (overdueLoansVisible == YES) return;
	overdueLoansVisible = YES;
	
	[GrowlApplicationBridge
		notifyWithTitle:	title
		description:		message
		notificationName:	OVERDUE_LOANS_NOTIFICATION
		iconData:			[[NSImage imageNamed: @"AsteriskRed"] TIFFRepresentation]
		priority:			0
		isSticky:			YES
		clickContext:		OVERDUE_LOANS_NOTIFICATION
	];
}

- (void) displayHoldsReadyMessage: (NSString *) message title: (NSString *) title
{
	if (holdsReadyVisible == YES) return;
	holdsReadyVisible = YES;
	
	[GrowlApplicationBridge
		notifyWithTitle:	title
		description:		message
		notificationName:	HOLDS_READY_NOTIFICATION
		iconData:			[[NSImage imageNamed: @"StarGreen"] TIFFRepresentation]
		priority:			0
		isSticky:			YES
		clickContext:		HOLDS_READY_NOTIFICATION
	];
}

// -----------------------------------------------------------------------------
//
// Detect when the dialog is dismissed.
//
// -----------------------------------------------------------------------------
- (void) growlNotificationWasClicked: (id) clickContext
{
	if ([clickContext isEqualToString: OVERDUE_LOANS_NOTIFICATION])
	{
		overdueLoansVisible = NO;
	}
	else if ([clickContext isEqualToString: HOLDS_READY_NOTIFICATION])
	{
		holdsReadyVisible = NO;
	}
}

- (void) growlNotificationTimedOut: (id) clickContext
{
	[self growlNotificationWasClicked: clickContext];
}

- (BOOL) hasNetworkClientEntitlement
{
	return YES;
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static Growl *sharedGrowl = nil;

+ (Growl *) sharedGrowl
{
    @synchronized(self)
	{
        if (sharedGrowl == nil)
		{
            sharedGrowl = [[Growl alloc] init];
        }
    }
	
    return sharedGrowl;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedGrowl == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedGrowl;
}

- (id) copyWithZone:(NSZone *)zone
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
    return NSUIntegerMax;
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