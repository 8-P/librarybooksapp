#import "ChicagoPublicLibrary.h"

@implementation ChicagoPublicLibrary

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"loginForm" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	[browser clickLink: @"View My CPL Account"];

//	[browser go: [Test fileURLFor: @"CARLweb/20090912_chicago_loans.html"]];
	[self parseLoans1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Parse loans and holds.
//
// Notes:
//		* Separate table for over due books.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans/holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	// Loans
	[scanner scanPassElementWithName: @"h3" attributeKey: @"id" attributeValue: @"checkedOut"];
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Due Date" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil];
		[self addLoans: rows];
	}
	
	// Over due loans
	[scanner scanPassElementWithName: @"h3" attributeKey: @"id" attributeValue: @"overdues"];
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Due Date" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil];
		[self addLoans: rows];
	}
	
	// Holds
	[scanner scanPassElementWithName: @"h3" attributeKey: @"id" attributeValue: @"holds"];
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Status" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil];
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
	return [browser linkToSubmitFormNamed: @"loginForm" entries: self.authenticationAttributes];
}

@end