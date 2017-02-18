#import "Test.h"
#import "Debug.h"

@implementation Test

+ (URL *) fileURLFor: (NSString *) testFile
{
	NSString *path = [@"/Users/harold/Desktop/librarybooks3/trunk/shared/testfiles/" stringByAppendingPathComponent: testFile];
	[Debug logError: @"USING DEBUG FILE - %@", path];
	return [URL fileURLWithPath: path];
}

@end