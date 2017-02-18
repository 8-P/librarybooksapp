// =============================================================================
//
// ExLibris Voyager
//
//		* ExLibris make 2 OPAC products (Aleph and Voyager)
//		* Original implementation based on University of Massachusetts Boston Library.
//		  Was given test account by librarian.
//
// =============================================================================

#import "Voyager.h"

@implementation Voyager

- (BOOL) update
{
	[browser go: catalogueURL];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary: self.authenticationAttributes];
	[attributes setObject: @"B" forKey: @"loginType"];
	if ([browser submitFormNamed: nil entries: attributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

	// Need to include <th> cells in the parsing
	scannerSettings.ignoreTableHeaderCells = NO;
	
//	[browser go: [Test fileURLFor: @"Voyager/20100810_massachusetts_loans.html"]];
	[self parseLoans1];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"",				@"Item Type",
		@"titleAndAuthor",	@"Item",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"tableChargedItems" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"titleAndAuthor", @"Item",
		nil
	];
	
	// Holds ready for pickup
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"tableAvailable" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHoldsReadyForPickup: rows];
	}

	// Holds pending
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"tablePendingReq" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
//		* Need to obfuscate the parameters.
//
// -----------------------------------------------------------------------------
#if 0
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary: self.authenticationAttributes];
	[attributes setObject: @"B" forKey: @"loginType"];

	return [browser linkToSubmitFormNamed: nil entries: attributes];
}
#endif

@end