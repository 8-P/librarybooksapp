// =============================================================================
//
// Koha
//
// =============================================================================

#import "Koha.h"

@implementation Koha

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/cgi-bin/koha/opac-user.pl?logout.x=1"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
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
	
//	if ([scanner scanNextElementWithName: @"div" attributeKey: @"id" attributeValue: @"opac-user-checkouts" intoElement: &element recursive: YES]
//		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"checkoutst" intoElement: &element recursive: YES])
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

	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"holdst" intoElement: &element recursive: YES])
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
	[browser go: [myAccountCatalogueURL URLWithPath: @"/cgi-bin/koha/opac-user.pl?logout.x=1"]];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end