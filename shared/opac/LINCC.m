// =============================================================================
//
// LINCC (Libraries of Clackamas County), OR, USA.
//
// It is a SIRSI system but has no "My Account" link and custom loan/hold pages.
//
// =============================================================================

#import "LINCC.h"

@implementation LINCC

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"loginform" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20090830_tpl_loans.html"]];
	[self parseLoans1];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// The auto column detection gets confused.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (LINCC format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Loans
	if ([scanner scanNextElementWithName: @"form" attributeKey: @"id" attributeValue: @"renewitems" intoElement: &element])
	{
		NSArray *columns = [element.scanner analyseLoanTableColumns];
		NSArray *rows = [element.scanner tableWithColumns: columns ];
		[self addLoans: rows];
	}
}

- (void) parseHolds1
{
	[Debug log: @"Parsing holds (LINCC format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Holds
	if ([scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"holds"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns = [NSArray arrayWithObjects: @"", @"titleAndAuthor", @"queuePosition", @"pickupAt", @"", @"queueDescription", nil];
		NSArray *rows = [element.scanner tableWithColumns: columns];
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
	return [browser linkToSubmitFormNamed: @"loginform" entries: self.authenticationAttributes];
}

@end