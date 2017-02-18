#import <Foundation/Foundation.h>

@interface NSDate (NSDateExtras)

+ (NSDate *) tomorrow;
+ (NSDate *) yesterday;
+ (NSDate *) today;
- (NSComparisonResult) reverseCompare: (NSDate *) anotherDate;
- (BOOL) isYesterday;
- (BOOL) isToday;
- (BOOL) isTomorrow;
- (NSDate *) dateWithoutTime;
- (NSDate *) dateByAddingDays: (NSUInteger) days;
- (NSDate *) dateBySubtractingDays: (NSUInteger) days;
- (NSString *) timeAgoString;

@end
