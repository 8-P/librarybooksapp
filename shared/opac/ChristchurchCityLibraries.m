// =============================================================================
//
// Christchurch City Libraries
//
//		* Login form appears first.
//		* Authentication parameters are non-standard (userid & pin
//		  vs user_id & password).
//
// =============================================================================

#import "ChristchurchCityLibraries.h"

@implementation ChristchurchCityLibraries

- (BOOL) update
{
	[browser go: catalogueURL];
	
	// Login
	if ([browser submitFormNamed: @"login" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20100717_christchurch_loans.html"]];
	[self parseLoans1];
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
	[Debug log: @"Parsing loans (Christchurch format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	if ([scanner scanPassString: @"Items checked out to this account"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
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
//		* Can't use <a name="holds" because there are two of these on the page
//		* Need to ignore first row because the title row doesn't use <th>
//		  so the table parser can't filter it out
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (Christchurch format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"queuePosition", @"Queue",
		nil
	];

	if ([scanner scanPassString: @"Titles on hold for this account"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: nil ignoreFirstRow: YES];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: catalogueURL];
	return [browser linkToSubmitFormNamed: @"login" entries: self.authenticationAttributes];
}

@end