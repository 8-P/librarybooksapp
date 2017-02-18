#import "Calendar.h"
#import "Debug.h"
#import "DataStore.h"

NSInteger const CalendarAlertNone			= 0;
NSInteger const CalendarAlertMessage		= 1;
NSInteger const CalendarAlertMessageSound	= 2;

@implementation Calendar

- (id) init
{
	self = [super init];

	defaults				= [[NSUserDefaults standardUserDefaults] retain];
	calendarStore			= [[CalCalendarStore defaultCalendarStore] retain];
	libraryBooksCalendar	= [[self libraryBooksCalendar] retain];
	
	return self;
}

- (void) dealloc
{
	[libraryBooksCalendar release];
	[defaults release];
	[calendarStore release];
	[super dealloc];
}

- (void) update
{
	[Debug log: @"Updating calendar [%@]", ([self enabled]) ? @"enabled" : @"disabled"];

	Calendar *calendar = [Calendar sharedCalendar];
	[calendar removeAllEvents];
	
	DataStore *dataStore = [DataStore sharedDataStore];
	NSArray *libraryCards = [dataStore selectLibraryCards];
	NSInteger count = 0;
	for (LibraryCard *libraryCard in libraryCards)
	{
		OrderedDictionary *dictionary = [dataStore loansGroupedByDueDateForLibraryCard: libraryCard];
		for (NSDate *dueDate in dictionary)
		{
			NSString *title = [NSString stringWithFormat: @"Library Items Due Today - %@", libraryCard.name];
			NSMutableString *notes = [NSMutableString string];
			for (Loan *loan in [dictionary objectForKey: dueDate])
			{
				[notes appendFormat: @"● %@\n", loan.title];
			}
			
			if ([self addEventWithTitle: title date: dueDate notes: notes])
			{
				count++;
			}
		}
	}
	
	[Debug log: @"Calendar - Added [%d] new events", count];
}

- (BOOL) addEventWithTitle: (NSString *) title date: (NSDate *) date notes: (NSString *) notes
{
	if ([self enabled] == NO) return NO;

	CalEvent *event			= [CalEvent event];
	event.calendar			= libraryBooksCalendar;
	event.title				= title;
	event.startDate			= date;
	event.endDate			= date;
	event.isAllDay			= YES;
	event.notes				= notes;
	
	// Remove any default alarms
	for (CalAlarm *alarm in event.alarms)
	{
		[event removeAlarm: alarm];
	}

	if ([self alertType] == CalendarAlertMessage || [self alertType] == CalendarAlertMessageSound)
	{
		// Add the new alarm
		CalAlarm *alarm			= [CalAlarm alarm];
		alarm.relativeTrigger	= [self alertTime];
		
		if ([self alertType] == CalendarAlertMessage)
		{
			alarm.action	= CalAlarmActionDisplay;
		}
		else
		{
			alarm.action	= CalAlarmActionSound;
			alarm.sound		= @"Pop";
		}

		[event addAlarm: alarm];
	}
	
	// Save the event
	NSError *error;
	if ([calendarStore saveEvent: event span: CalSpanAllEvents error: &error] == NO)
	{
		[Debug logDetails: [error description] withSummary: @"Calendar - failed to save event"];
		return NO;
	}
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Clear all the events.
//
// -----------------------------------------------------------------------------
- (void) removeAllEvents
{
	if (libraryBooksCalendar == nil) return;
	if ([self enabled] == NO) return;

	// Get all Library Books events
	//
	//		* The predicate needs to be within a 4-year range
	NSPredicate *predicate = [CalCalendarStore
		eventPredicateWithStartDate:	[NSDate dateWithTimeIntervalSinceNow: -86400 * 90]
		endDate:						[NSDate distantFuture]
		calendars:						[NSArray arrayWithObject: libraryBooksCalendar]
	];
	NSArray *events = [calendarStore eventsWithPredicate: predicate];
	
	// Remove all events
	NSInteger count = 0;
	for (CalEvent *event in events)
	{
		if ([event.title hasPrefix: @"Library Items Due Today"])
		{
			NSError *error = nil;
			if ([calendarStore removeEvent: event span: CalSpanAllEvents error: &error] == NO)
			{
				[Debug logDetails: [error description] withSummary: @"Calendar - failed to remove event"];
			}
			else
			{
				count++;
			}
		}
	}
	
	[Debug log: @"Calendar - Deleted [%d] old events", count];
}

- (CalCalendar *) libraryBooksCalendar
{
	if ([self enabled] == NO) return nil;

	CalCalendar *calendar = nil;
	NSString *uid  = [defaults stringForKey: @"CalendarUID"];
	if (uid != nil)
	{
		calendar = [calendarStore calendarWithUID: uid];
	}
	
	if (calendar == nil)
	{
		for (CalCalendar *c in [calendarStore calendars])
		{
			if ([c.title isEqualToString: @"Library Books"])
			{
				calendar = c;
				break;
			}
		}
	}

	if (calendar == nil)
	{
		calendar 		= [CalCalendar calendar];
		calendar.title	= [self uniqueCalendarTitle];
		
		NSError *error = nil;
		if ([calendarStore saveCalendar: calendar error: &error] == NO)
		{
			[Debug logDetails: [error description] withSummary: @"Calendar - failed to save calendar"];
			return nil;
		}
		
		[Debug logDetails: [calendar description] withSummary: @"Created new calendar"];
		
		// Save the UID
		[defaults setObject: calendar.uid forKey: @"CalendarUID"];
		[defaults synchronize];
	}
	
	return calendar;
}

- (BOOL) enabled
{
	return [defaults boolForKey: @"ICalAlert"];
}

- (NSInteger) alertType
{
	return [defaults integerForKey: @"ICalAlertType"];
}

- (NSTimeInterval) alertTime
{
	NSDate *date					= [defaults objectForKey: @"ICalAlertTime"];
	NSCalendar *calendar			= [NSCalendar currentCalendar];
	NSDateComponents *components	= [calendar components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: date];
	
	return [components hour] * 3600 + [components minute] * 60;
}

// -----------------------------------------------------------------------------
//
// Generate a unique calendar title.  It will try these names in sequence:
//
//		Library Books
//		Library Books (2)
//		Library Books (3)
//		...
//
// -----------------------------------------------------------------------------
- (NSString *) uniqueCalendarTitle
{
	// Make hash of the current titles
	NSMutableDictionary *existingCalendarTitles = [NSMutableDictionary dictionary];
	for (CalCalendar *calendar in [calendarStore calendars])
	{
		[existingCalendarTitles setObject: @"" forKey: calendar.title];
	}
	
	// Search for a unique title
	for (int i = 1; i < 100; i++)
	{
		NSString *suffix = (i == 1) ? @"" : [NSString stringWithFormat: @" (%d)", i];
		NSString *title = [NSString stringWithFormat: @"Library Books%@", suffix];
		
		if ([existingCalendarTitles objectForKey: title] == nil)
		{
			return title;
		}
	}
	
	return nil;
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static Calendar *sharedCalendar = nil;

+ (Calendar *) sharedCalendar
{
    @synchronized(self)
	{
        if (sharedCalendar == nil)
		{
            sharedCalendar = [[Calendar alloc] init];
        }
    }
	
    return sharedCalendar;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedCalendar == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedCalendar;
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