// =============================================================================
//
// Bookit
//
// Original implementation based on Värmdö kommunbibliotek.
//
//		* Uses frames.
//
// =============================================================================

#import "Bookit.h"

@implementation Bookit

- (BOOL) update
{
	URL *baseURL		= [self baseURL];
	NSString *inUserId	= [self inUserId: baseURL];

	// Logout
	[browser go: [baseURL URLWithPath: @"pkg_www_setup.print_exit"]];

	// Set the language to English
	[browser go: [baseURL URLWithPathFormat: @"pkg_www_misc.print_index?in_language_id=en_GB&in_user_id=%@", inUserId]];
	[browser go: [baseURL URLWithPath: @"pkg_www_loan.get_loan"]];
	
	if ([browser submitFormNamed: nil entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	// The URLs a quite predictable so we just formulate them
	URL *itemsURL = [baseURL URLWithPath: @"pkg_www_loan.get_loan"];
	URL *holdsURL = [baseURL URLWithPath: @"pkg_www_booking.get_booking"];

//	itemsURL = [Test fileURLFor: @"Bookit/20121224_vasteras_loans.html"];

	[browser go: itemsURL];
	[self parseLoans1];
	
	[browser go: holdsURL];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Parse loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"form" attributeKey: @"action" attributeValue: @"pkg_www_loan.print_loan" intoElement: &element]
		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse holds.
//
//		* Need to ignore the table header row (we look for the TableHeaderMiddle
//		  string).
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"pickupAt",		@"Collect at",
		@"readyForPickup",	@"Collect",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"form" attributeKey: @"action" attributeValue: @"pkg_www_booking.print_booking" intoElement: &element]
		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *ignoreRows	= [NSArray arrayWithObject: @"TableHeaderMiddle"];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: ignoreRows delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Figure out the parmeter in_user_id value for the library.
//
//		* It is needed in the URL request otherwise it won't authenticate.
//		* The value is stored as a variable in index.js.
//
// -----------------------------------------------------------------------------
- (NSString *) inUserId: (URL *) baseURL
{
	URL *localURL = [URL URLWithString: [[baseURL absoluteString] stringByReplacingOccurrencesOfString: @"/pls/" withString: @"/local/"]];
	[browser go: [localURL URLWithPath: @"search/js/index.js"]];
	
	NSString *inUserId = nil;
	if ([browser.scanner scanRegex: @"in_user_id=\"(.+?)\"" capture: 1 intoString: &inUserId] == NO)
	{
		[Debug log: @"Failed to get in_user_id"];
		return nil;
	}
	
	return inUserId;
}

- (URL *) baseURL
{
	[browser go: [catalogueURL URLWithPath: @"/pls/bookit/"]];
	
	NSString *path = [browser.currentURL.absoluteString stringByMatching: @"(/pls/bookit\\d*/)" capture: 1];
	URL *baseURL = [browser.currentURL URLWithPath: path];
	
	[Debug log: @"Base URL [%@]", baseURL.absoluteString];
	return baseURL;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
#if 0
- (URL *) myAccountURL
{
	NSString *inUserId = [self inUserId];

	[browser go: [catalogueURL URLWithPath: @"/pls/bookit/"]];
	[browser go: [browser.currentURL URLWithPathFormat: @"/pls/bookit/pkg_www_misc.print_index?in_language_id=sv_SE&in_user_id=%@", inUserId]];
	[browser go: [browser.currentURL URLWithPath: @"/pls/bookit/pkg_www_loan.get_loan"]];
	
	return [browser linkToSubmitFormNamed: nil entries: self.authenticationAttributes];
}
#endif

@end