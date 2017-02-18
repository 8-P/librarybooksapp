#import "NSDateExtras.h"

@implementation NSDate (NSDateExtras)

+ (NSDate *) tomorrow
{
	NSDate *startOfToday	= [NSDate today];
	NSCalendar *calendar	= [NSCalendar currentCalendar];
	
	// Offset by 24 hours to get tomorrow
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setHour: 25];
	NSDate *tomorrow = [calendar dateByAddingComponents: offsetComponents toDate: startOfToday options: 0];
	[offsetComponents release];
	
	return [tomorrow dateWithoutTime];
}

+ (NSDate *) yesterday
{
	NSDate *startOfToday	= [NSDate today];
	NSCalendar *calendar	= [NSCalendar currentCalendar];
	
	// Offset by 24 hours to get yesterday
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setHour: -23];
	NSDate *yesterday = [calendar dateByAddingComponents: offsetComponents toDate: startOfToday options: 0];
	[offsetComponents release];
	
	return [yesterday dateWithoutTime];
}

// -----------------------------------------------------------------------------
//
// Figure out the start of today.
//
// -----------------------------------------------------------------------------
+ (NSDate *) today
{
	return [[NSDate date] dateWithoutTime];
}

- (NSComparisonResult) reverseCompare: (NSDate *) anotherDate
{
	NSComparisonResult result = [self compare: anotherDate];
	if      (result == NSOrderedAscending)  result = NSOrderedDescending;
	else if (result == NSOrderedDescending) result = NSOrderedAscending;
	
	return result;
}

- (BOOL) isYesterday
{
	return [self isEqualToDate:	[NSDate yesterday]];
}

- (BOOL) isToday
{
	return [[self dateWithoutTime] isEqualToDate: [NSDate today]];
}

- (BOOL) isTomorrow
{
	return [self isEqualToDate:	[NSDate tomorrow]];
}

- (NSDate *) dateWithoutTime
{
	NSCalendar *calendar			= [NSCalendar currentCalendar];
	NSDateComponents *components	= [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate: self];
	return [calendar dateFromComponents: components];
}

// -----------------------------------------------------------------------------
//
// Calculate a new date by offsetting it by n days.
//
// -----------------------------------------------------------------------------
- (NSDate *) dateByAddingDays: (NSUInteger) days
{
	NSDate *date			= [self dateWithoutTime];
	NSCalendar *calendar	= [NSCalendar currentCalendar];
	
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setHour: 25];
	
	for (int i = 0; i < days; i++)
	{
		date = [[calendar dateByAddingComponents: offsetComponents toDate: date options: 0] dateWithoutTime];
	}
	
	[offsetComponents release];
	
	return date;
}

- (NSDate *) dateBySubtractingDays: (NSUInteger) days
{
	NSDate *date			= [self dateWithoutTime];
	NSCalendar *calendar	= [NSCalendar currentCalendar];
	
	NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
	[offsetComponents setHour: -23];
	
	for (int i = 0; i < days; i++)
	{
		date = [[calendar dateByAddingComponents: offsetComponents toDate: date options: 0] dateWithoutTime];
	}
	
	[offsetComponents release];
	
	return date;
}

// -----------------------------------------------------------------------------
//
// Return the time string formated like "x days ago."
//
// -----------------------------------------------------------------------------
- (NSString *) timeAgoString
{
	NSString *string = nil;
	NSTimeInterval diff	= -1 * [self timeIntervalSinceNow];

	if (diff > 86400 * 2)
	{
		string = [NSString stringWithFormat: @"updated %0.0f days ago",
			diff / 86400];
	}
	else if (diff > 86400)
	{
		string = @"1 day ago";
	}
	else if (diff > 3600)
	{
		double hours = diff / 3600;
		string = [NSString stringWithFormat: @"updated %0.0f hour%s ago",
			hours,
			(hours < 1.5) ? "" : "s"];
	}
	else if (diff > 60)
	{
		double minutes = diff / 60;
		string = [NSString stringWithFormat: @"updated %0.0f minute%s ago",
			minutes,
			(minutes < 1.5) ? "" : "s"];
	}
	else
	{
		string = @"just updated";
	}
	
	return string;
}
/*
- (NSString *) timeAgoString
{
	NSString *string = nil;
	NSTimeInterval diff	= -[self timeIntervalSinceNow];

	if (diff > 86400 * 2)
	{
		string = [NSString stringWithFormat: @"%0.0f days ago",
			diff / 86400 ];
	}
	else if (diff > 86400)
	{
		string = @"1 day ago";
	}
	else if (diff > 3600)
	{
		string = [NSString stringWithFormat: @"%0.0f hour%s ago",
			diff / 3600,
			(diff / 3600 < 2) ? "" : "s"];
	}
	else if (diff > 60)
	{
		string = [NSString stringWithFormat: @"%0.0f minute%s ago",
			diff / 60,
			(diff / 60 < 2) ? "" : "s"];
	}
	else
	{
		string = @"less than 1 minute ago";
	}
	
	return string;
}*/

@end