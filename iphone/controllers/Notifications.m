#import "Notifications.h"
#import "DataStore.h"
#import "Settings.h"
#import "SharedExtras.h"

@implementation Notifications

+ (Notifications *) notifications
{
	return [[[Notifications alloc] init] autorelease];
}

- (id) init
{
	self = [super init];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) update
{	
	Class localNotificationClass = [self localNotificationClass];
	if (localNotificationClass == nil) return;

	UIApplication *app = [UIApplication sharedApplication];
	[app cancelAllLocalNotifications];
	
	Settings *settings = [Settings sharedSettings];
	DataStore *dataStore = [DataStore sharedDataStore];

	int count = 0;
	OrderedDictionary *dueDates = [dataStore dueDatesForActiveLibraries];
	for (NSDate *dueDate in dueDates)
	{
		count += [[dueDates objectForKey: dueDate] intValue];

		// App badge warnings
		if (settings.appBadge)
		{
			UILocalNotification *alarm = [[localNotificationClass alloc] init];
			if (alarm)
			{
				alarm.fireDate						= [dueDate dateBySubtractingDays: [settings.overdueAlertValue integerValue]];
				alarm.timeZone						= [NSTimeZone defaultTimeZone];
				alarm.applicationIconBadgeNumber	= count;
				
				[app scheduleLocalNotification: alarm];
				[alarm release];
			}
		}
		
		// Over due notifications
		if (settings.overdueNotification)
		{
			UILocalNotification *alarm = [[localNotificationClass alloc] init];
			if (alarm)
			{
				alarm.fireDate	= dueDate;
				alarm.timeZone	= [NSTimeZone defaultTimeZone];
				alarm.alertBody = [NSString stringWithFormat: @"%d library items due today", count];
				
				[app scheduleLocalNotification: alarm];
				[alarm release];
			}
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"BadgesNeedReloading" object: self];
}

- (Class) localNotificationClass
{
	return NSClassFromString(@"UILocalNotification");
}

@end