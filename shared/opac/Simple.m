// =============================================================================
//
// Simple OPAC so other people and implement their own interfaces.
//
// =============================================================================

#import "Simple.h"

@implementation Simple

- (BOOL) update
{
	catalogueURL.attributes = self.authenticationAttributes;
	[browser go: catalogueURL];
	[self authenticationOK];

	NSDictionary *dictionary = [JSON toJson: [browser.scanner string]];
	if (dictionary)
	{
		[self addLoans: [dictionary objectAtPath: @"loans"]];
		[self addHolds: [dictionary objectAtPath: @"holds"]];
	}
	
	return YES;
}

@end