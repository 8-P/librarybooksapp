// =============================================================================
//
// CARLweb
//
// Original implementation based on Arlington Public Library, VA, USA.
//
// Notes:
//		* CARLweb uses frames.
//		* The loan and hold pages are generated dynamically using JavaScript.
//		  The details are store in JavaScript data structures so these need to
//		  be parsed to get the data.
//		* Overdue loans are on a separate page.
//
// =============================================================================

#import "CARLweb.h"

@implementation CARLweb

- (BOOL) update
{
	[browser focusOnFrameNamed: @"Content"];
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: nil entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	URL *itemsURL			= [browser firstLinkForLabels: [NSArray arrayWithObjects: @"Checked out", @"Loaned", @"Loans", nil]];
	URL *overdueItemsURL	= [browser firstLinkForLabels: [NSArray arrayWithObjects: @"Overdue Items and Claims", @"Overdue Items", nil]];
	URL *holdsURL			= [browser firstLinkForLabels: [NSArray arrayWithObjects: @"Holds", @"Reserves", nil]];
	
	[browser go: itemsURL];
	[self parseLoans1];
	
	[browser go: overdueItemsURL];
	[self parseOverdueLoans1];
	
	[browser go: holdsURL];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Parse loans.
//
// Notes:
//		* The data is in a JavaScript data structure and the table is generated
//		  dynamically.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner = browser.scanner;
	
	NSString *string = nil;
	if ([scanner scanFromString: @"var CHARGES = [" upToString: @"];" intoString: &string])
	{
		NSScanner *loansScanner = [NSScanner scannerWithString: string];
		NSDictionary *mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			// LB key,				CARLweb key
			@"title",				@"title",
			@"author",				@"author",
			@"isbn",				@"isbn",
			@"dueDate",				@"dueDate",
			nil
		];
		NSArray *rows = [loansScanner javascriptWithKeyMapping: mapping];
		
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse overdue loans.
//
// -----------------------------------------------------------------------------
- (void) parseOverdueLoans1
{
	[Debug log: @"Parsing overdue loans (format 1)"];
	NSScanner *scanner = browser.scanner;
	
	// TODO: fix this up - untested code
	
	NSString *string = nil;
	if ([scanner scanFromString: @"var CHARGES = [" upToString: @"];" intoString: &string])
	{
		NSScanner *loansScanner = [NSScanner scannerWithString: string];
		NSDictionary *mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			// LB key,				CARLweb key
			@"title",				@"title",
			@"author",				@"author",
			@"isbn",				@"isbn",
			@"dueDate",				@"dueDate",
			nil
		];
		NSArray *rows = [loansScanner javascriptWithKeyMapping: mapping];
		
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	
	NSString *string = nil;
	if ([scanner scanFromString: @"var HOLDS = [" upToString: @"];" intoString: &string])
	{
		NSScanner *holdsScanner = [NSScanner scannerWithString: string];
		NSDictionary *mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			// LB key,				CARLweb key
			@"title",				@"title",
			@"author",				@"author",
			@"isbn",				@"isbn",
			@"pickupAt",			@"holdPickupBranch",
			@"queueDescription",	@"status",
			@"queuePosition",		@"queuePosition",
			nil
		];
		NSArray *rows = [holdsScanner javascriptWithKeyMapping: mapping];
		
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
	[browser focusOnFrameNamed: @"Content"];
	[browser go: myAccountCatalogueURL];

	return [browser linkToSubmitFormNamed: nil entries: self.authenticationAttributes];
}

@end