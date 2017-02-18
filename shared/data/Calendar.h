#import <Foundation/Foundation.h>
#import "Loan.h"
#import <CalendarStore/CalendarStore.h>

extern NSInteger const CalendarAlertNone;
extern NSInteger const CalendarAlertMessage;
extern NSInteger const CalendarAlertMessageSound;

@interface Calendar : NSObject
{
	CalCalendar			*libraryBooksCalendar;
	NSUserDefaults		*defaults;
	CalCalendarStore	*calendarStore;
}

- (void) update;
- (BOOL) addEventWithTitle: (NSString *) title date: (NSDate *) date notes: (NSString *) notes;
- (void) removeAllEvents;
- (CalCalendar *) libraryBooksCalendar;
- (BOOL) enabled;
- (NSInteger) alertType;
- (NSTimeInterval) alertTime;
- (NSString *) uniqueCalendarTitle;

+ (Calendar *) sharedCalendar;

@end