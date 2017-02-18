#import <Foundation/Foundation.h>

@interface DateParser : NSObject
{
	NSDateFormatter		*dateFormatter;
	NSString			*dateFormat;
	NSArray				*dayMonthYearDateFormats;
	NSArray				*monthDayYearDateFormats;
	NSArray				*yearMonthDayDateFormats;
	NSMutableDictionary *dateFormatRegexs;
}

@property(retain)	NSString	*dateFormat;
@property(readonly)	NSArray		*dayMonthYearDateFormats;
@property(readonly)	NSArray		*monthDayYearDateFormats;
@property(readonly)	NSArray		*yearMonthDayDateFormats;

+ (DateParser *) dateParser;
- (NSDate *) dateFromString: (NSString *) string;
- (NSDate *) dateFromString: (NSString *) string dateFormat: (NSString *) dateFormat;
- (NSString *) regexForDateFormat: (NSString *) dateFormat;

@end