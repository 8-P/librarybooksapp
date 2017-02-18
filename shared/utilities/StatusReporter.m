#import "StatusReporter.h"
#import "URL.h"
#import "Debug.h"

#define FREE 1

@implementation StatusReporter

+ (void) reportStatus: (NSInteger) status libraryIdentifier: (NSString *) identifier
{
// Don't send status report on iPhone as it slows the updates down
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || APP_STORE || FREE
	return;
#else
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey: @"AllowStatusReport"] == NO) return;

	NSDate *lastStatusReport = [defaults objectForKey: @"LastStatusReport"];
	NSTimeInterval secondsSinceLastStatusReport = -1 * [lastStatusReport timeIntervalSinceNow];
	if (secondsSinceLastStatusReport > 86400)
	{
		[Debug log: @"Sending status report for library [%@] status [%d]", identifier, status];
		URL *url = [URL URLWithFormat: @"http://librarybooksapp.com/status.cgi?i=%@&s=%d", identifier, status];
		[url download];
	}
#endif
}

+ (void) delayStatusReportsForADay
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || APP_STORE || FREE
	return;
#else
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey: @"AllowStatusReport"] == NO) return;
	
	[defaults setObject: [NSDate date] forKey: @"LastStatusReport"];
	[defaults synchronize];
#endif
}

@end