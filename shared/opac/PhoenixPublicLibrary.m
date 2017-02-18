// =============================================================================
//
// PhoenixPublicLibrary
//
// =============================================================================

#import "PhoenixPublicLibrary.h"

@implementation PhoenixPublicLibrary

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/logout.jsp"]];
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Cannot to find login form"];
		return NO;
	}
	[self authenticationOK];
	
	URL *holdsURL				= [browser linkForLabel: @"Hold Requests"];
	URL *holdsReadyForPickupURL = [browser linkForLabel: @"Holds for Pickup"];
	
//	[browser go: [Test fileURLFor: @"Ungrouped/20120126_phoenix_loans.html"]];	
	
	[self parseLoans1];
	
	if (holdsURL)
	{
		[self parseHoldsReadyForPickup1: NO];
	}
	
	if (holdsReadyForPickupURL)
	{
		[self parseHoldsReadyForPickup1: YES];
	}
	
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
		@"parseLoanTitleCell:", @"Title",
		nil
	];
	
	if ([scanner scanPassString: @"ITEMS CHECKED OUT"]
		&& [scanner scanNextElementWithName: @"table" regexValue: @"Due Date" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// -----------------------------------------------------------------------------
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"holdst" intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];

		if (readyForPickup)	[self addHoldsReadyForPickup: rows];
		else				[self addHolds:               rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing of the title cell.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseLoanTitleCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a .*?>(.*?)</a>",									@"title",
		@"<strong>No. of Renewals:</strong>\\s*(\\d+)<br />",	@"timesRenewed",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	NSDictionary *result = [scanner dictionaryUsingRegexMapping: mapping];
	if ([result count] == 0)
	{
		// Fall back to using the whole string as the title
		result = [NSDictionary dictionaryWithObject: [string stringWithoutHTML] forKey: @"title"];
	}
	
	return result;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: [myAccountCatalogueURL URLWithPath: @"/logout.jsp"]];
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end