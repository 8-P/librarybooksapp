// =============================================================================
//
// Test library for testing the display of items.
//
// The fake list of loans and holds are in TestLibraryData.plist.
//
// =============================================================================

#import "TestLibrary.h"

@implementation TestLibrary

- (BOOL) update
{
	NSString *filePath	= [[NSBundle mainBundle] pathForResource: [properties objectForKey: @"DataFile"] ofType: @"plist"];
	NSDictionary *data	= [NSDictionary dictionaryWithContentsOfFile: filePath];
	
	// Add the loans and holds
	[self addLoans: [data objectForKey: @"Loans"]];
	[self addHolds: [data objectForKey: @"Holds"]];

	return YES;
}

@end