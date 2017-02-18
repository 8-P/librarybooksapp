#import "Sparkle.h"

@implementation Sparkle

- (id) init
{
	self = [super init];

	SUUpdater *updater = [SUUpdater sharedUpdater];
	[updater setDelegate: self];
	
	return self;
}

- (id <SUVersionComparison>) versionComparatorForUpdater: (SUUpdater *) updater
{
	return self;
}

- (NSComparisonResult) compareVersion: (NSString *) version1 toVersion: (NSString *) version2
{
	NSNumber *number1 = [self numberForVersionString: version1];
	NSNumber *number2 = [self numberForVersionString: version2];

	NSLog(@"Upgrade check: [%@ (%d)] ->  [%@ (%d)]", version1, [number1 intValue], version2, [number2 intValue]);

	return [number1 compare: number2];
}

- (NSNumber *) numberForVersionString: (NSString *) string
{
	NSArray *n = [string captureComponentsMatchedByRegex: @"(\\d+)\\.(\\d+)(?:b(\\d+))?"];
	if ([n count] != 4) return [NSNumber numberWithInteger: 0];
	
	NSInteger major = [[n objectAtIndex: 1] integerValue];
	NSInteger minor = [[n objectAtIndex: 2] integerValue];
	NSInteger beta	= [[n objectAtIndex: 3] integerValue];
	
	return [NSNumber numberWithInteger:
		  major * 1000000
		+ minor *    1000
		+ ((beta > 0) ? beta - 1000 : 0)
	];
}

@end