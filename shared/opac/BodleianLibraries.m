// =============================================================================
//
// Bodleian Libraries (Oxford University)
//
// =============================================================================

#import "BodleianLibraries.h"

@implementation BodleianLibraries

- (BOOL) update
{
	[browser go: catalogueURL];

// TODO logout

	NSString *url;
	if ([browser.scanner scanFromString: @"onload=\"location = '" upToString: @"'" intoString: &url])
	{
		[Debug log: @"Following redirect 1 [%@]", url];
		[browser go: [browser.currentURL URLWithPath: url]];
	}

	[browser clickLink: @"Oxford SSO"];
	
	if ([browser.scanner scanFromString: @"onload=\"location = '" upToString: @"'" intoString: &url])
	{
		[Debug log: @"Following redirect 2 [%@]", url];
		[browser go: [browser.currentURL URLWithPath: url]];
	}
	
	if ([[browser.scanner string] hasSubString: @"press the Continue button once to proceed"])
	{
		URL *formUrl = [browser linkToSubmitFormNamed: nil entries: nil];
		[Debug log: @"Following SSO post redirect [%@]", url];
		[browser go: formUrl];
	}
	
	[Debug logError: @"URL = %@", [browser.currentURL absoluteString]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Cannot to find login form"];
		return NO;
	}
	[self authenticationOK];
	
	[browser clickLink: @"Confirm"];
	
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
//		* Too hard to deal with the SSO.
//
// -----------------------------------------------------------------------------
#if 0
- (URL *) myAccountURL
{
	return nil;
}
#endif

@end