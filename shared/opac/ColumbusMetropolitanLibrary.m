// =============================================================================
//
// Columbus Metropolitan Library
//
// =============================================================================

#import "ColumbusMetropolitanLibrary.h"

@implementation ColumbusMetropolitanLibrary

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"Ungrouped/20110426_columbus_loans.html"]];
	
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
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"check_outs" intoElement: &element])
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
	
	// Holds ready for pickup
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"tableAvailable" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHoldsReadyForPickup: rows];
	}

	// Holds pending
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"reserves_requested" intoElement: &element])
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
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end