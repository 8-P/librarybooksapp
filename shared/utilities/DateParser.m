#import "DateParser.h"
#import "SharedExtras.h"
#import "RegexKitLite.h"
#import "Debug.h"

@implementation DateParser

@synthesize dateFormat;
@dynamic dayMonthYearDateFormats, monthDayYearDateFormats, yearMonthDayDateFormats;

+ (DateParser *) dateParser
{
	return [[[DateParser alloc] init] autorelease];
}

- (id) init
{
	self = [super init];
	
	// * Make sure the date formatter is using English as the locale so it can
	//   handle long month names
	// * The OPAC implementation will try and download the page in English
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLenient: YES];
	[dateFormatter setLocale: [[[NSLocale alloc] initWithLocaleIdentifier: @"en_US"] autorelease]];
	
	dayMonthYearDateFormats = nil;
	monthDayYearDateFormats = nil;
	yearMonthDayDateFormats = nil;
	
	dateFormatRegexs = [[NSMutableDictionary dictionary] retain];
	
	return self;
}

- (void) dealloc
{
	[dateFormatter release];
	[dateFormat release];
	[dayMonthYearDateFormats release];
	[monthDayYearDateFormats release];
	[yearMonthDayDateFormats release];
	[dateFormatRegexs release];
	
	[super dealloc];
}


// -----------------------------------------------------------------------------
//
// Parse the date.
//
// -----------------------------------------------------------------------------
- (NSDate *) dateFromString: (NSString *) string
{
	if (string == nil) return nil;

	if ([dateFormat hasSubString: @"year"])
	{
		// Get the list of date formats to try
		NSArray *dateFormats;
		if		([dateFormat isEqualToString: @"day month year"])	dateFormats = self.dayMonthYearDateFormats;
		else if ([dateFormat isEqualToString: @"month day year"])	dateFormats = self.monthDayYearDateFormats;
		else if ([dateFormat isEqualToString: @"year month day"])	dateFormats = self.yearMonthDayDateFormats;
		else
		{
			// An invalid date format was set the libraries plist.  Most likely
			// it was caused by a typo, e.g. an extra space character etc.
			[Debug logError: @"Invalid date format [%@]", dateFormat];
			return nil;
		}
		
		// Normalise the date string by removing the separators. (For the regex
		// to work the the hypen needs to be last in the list.)
		string = [string stringByReplacingOccurrencesOfRegex: @"[ ,./'-]+" withString: @" "];
		
		// Try each date format until get a match
		for (NSString *format in dateFormats)
		{
			NSDate *date = [self dateFromString: string dateFormat: format];
			if (date) return date;
		}
	}
	else
	{
		[dateFormatter setDateFormat: dateFormat];
		return [dateFormatter dateFromString: string];
	}
	
	return nil;
}

- (NSDate *) dateFromString: (NSString *) string dateFormat: (NSString *) format
{
	NSString *regex = [self regexForDateFormat: format];
	NSString *dateString = [string stringByMatching: regex capture: 1];
	if (dateString)
	{
		[dateFormatter setDateFormat: format];
		return [dateFormatter dateFromString: dateString];
	}
	
	return nil;
}

- (NSArray *) dayMonthYearDateFormats
{
	if (dayMonthYearDateFormats == nil)
	{
		dayMonthYearDateFormats = [NSArray arrayWithObjects:
			@"EEE dd MMMM yyyy",
			@"EEE dd MMM yyyy",
			@"EEE dd MMM yy",
			@"dd MMMM yyyy",
			@"dd MMM yyyy",
			@"dd MM yyyy",
			@"dd MMM yy",
			@"dd MM yy",
			nil
		];
		[dayMonthYearDateFormats retain];
	}
	
	return dayMonthYearDateFormats;
}

- (NSArray *) monthDayYearDateFormats
{
	if (monthDayYearDateFormats == nil)
	{
		monthDayYearDateFormats = [NSArray arrayWithObjects:
			@"EEE MMMM dd yyyy",
			@"EEE MMM dd yyyy",
			@"EEE MMM dd yy",
			@"MMMM dd yyyy",
			@"MMM dd yyyy",
			@"MMM dd yy",
			@"MM dd yyyy",
			@"MM dd yy",
			nil
		];
		[monthDayYearDateFormats retain];
	}
	
	return monthDayYearDateFormats;
}

- (NSArray *) yearMonthDayDateFormats
{
	if (yearMonthDayDateFormats == nil)
	{
		yearMonthDayDateFormats = [NSArray arrayWithObjects:
			@"yyyy MMMM dd",
			@"yyyy MMM dd",
			@"yyyy MM dd",
			@"yy MMM dd",
			@"yy MM dd",
			nil
		];
		[yearMonthDayDateFormats retain];
	}
	
	return yearMonthDayDateFormats;
}

// -----------------------------------------------------------------------------
//
// Get the regex for a date format.
//
// -----------------------------------------------------------------------------
- (NSString *) regexForDateFormat: (NSString *) format
{
	NSMutableString *regex = [dateFormatRegexs objectForKey: format];
	if (regex == nil)
	{
		regex = [NSMutableString stringWithFormat: @"(%@)", format];

		[regex replaceOccurrencesOfRegex: @"\\bdd\\b"		withString: @"\\\\d{1,2}"];
		[regex replaceOccurrencesOfRegex: @"\\bMM\\b"		withString: @"\\\\d{1,2}"];
		[regex replaceOccurrencesOfRegex: @"\\bM{3,}\\b"	withString: @"\\\\S+"];
		[regex replaceOccurrencesOfRegex: @"\\byy\\b"		withString: @"\\\\d{2}"];
		[regex replaceOccurrencesOfRegex: @"\\byyyy\\b"		withString: @"(?:19|20)\\\\d{2}"];
		[regex replaceOccurrencesOfRegex: @"\\bEEE\\b"		withString: @"\\\\S+"];
		
		[dateFormatRegexs setObject: regex forKey: format];
	}
	
	return regex;
}

@end