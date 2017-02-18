// =============================================================================
//
// CARLweb
//
//		* Version 5.4
//		* Based on Monroe County Library (NY)
//
// =============================================================================

#import "CARLweb2.h"

@implementation CARLweb2

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to find login form"];
		return NO;
	}
	[self authenticationOK];
	
	URL *loansURL			= [browser firstLinkForLabels: [NSArray arrayWithObjects: @"Checked out", @"Loaned", @"Loans", nil]];
	URL *overdueLoansURL	= [browser firstLinkForLabels: [NSArray arrayWithObjects: @"Overdue Items", nil]];
	URL *holdsURL			= [browser firstLinkForLabels: [NSArray arrayWithObjects: @"Holds", @"Reserves", nil]];
	
//	loansURL = [Test fileURLFor: @"CARLweb/20110430_monroe_loans.html"];
	
	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1];
	}
	
	if (overdueLoansURL)
	{
		[browser go: overdueLoansURL];
		[self parseLoans1];
	}
	
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHolds1];
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

	[scanner scanPassElementWithName: @"head"];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Due Date" intoElement: &element])
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

	[scanner scanPassElementWithName: @"head"];

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
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end