#import <Cocoa/Cocoa.h>

@interface Preferences : NSObject
{
	NSUserDefaults	*defaults;
}

@property(readonly) NSInteger dueSoonWarningDays;

+ (Preferences *) sharedPreferences;

@end