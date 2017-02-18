// =============================================================================
//
// Bookit 3
//
//		* Goes to /local/bookit3/search/js/index.js instead of
//		          /local/bookit0/search/js/index.js
//
// =============================================================================

#import "Bookit3.h"

@implementation Bookit3

// -----------------------------------------------------------------------------
//
// Figure out the parmeter in_user_id value for the library.
//
//		* It is needed in the URL request otherwise it won't authenticate.
//		* The value is stored as a variable in index.js.
//
// -----------------------------------------------------------------------------
- (NSString *) inUserId
{
	[browser go: [catalogueURL URLWithPath: @"/pls/bookit/"]];
	[browser go: [browser.currentURL URLWithPath: @"/local/bookit3/search/js/index.js"]];
	
	NSString *inUserId = nil;
	if ([browser.scanner scanRegex: @"in_user_id=\"(.+?)\"" capture: 1 intoString: &inUserId] == NO)
	{
		[Debug log: @"Failed to get in_user_id"];
		return nil;
	}
	
	return inUserId;
}

@end