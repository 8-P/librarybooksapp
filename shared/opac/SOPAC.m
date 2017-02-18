// =============================================================================
//
// SOPAC
//
// =============================================================================

#import "SOPAC.h"

@implementation SOPAC

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/logout"]];
	[browser go: [catalogueURL URLWithPath: @"/user"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	URL *loansURL = [browser.currentURL URLWithPath: @"/user/checkouts"];
	URL *holdsURL = [browser.currentURL URLWithPath: @"/user/holds"];
	
//	[browser go: [Test fileURLFor: @"SOPAC/20101121_pvld_loans.html"]];
	[browser go: loansURL];
	[self parseLoans1];

//	[browser go: [Test fileURLFor: @"SOPAC/20101121_pvld_holds.html"]];	
	[browser go: holdsURL];
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
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"patroninfo" intoElement: &element recursive: YES])
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

	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"patroninfo" intoElement: &element recursive: YES])
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
	[browser go: [myAccountCatalogueURL URLWithPath: @"/logout"]];
	[browser go: [myAccountCatalogueURL URLWithPath: @"/user"]];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end