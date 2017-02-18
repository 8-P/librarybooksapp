// =============================================================================
//
// SOPAC 2
//
//		* Loans and holds in combined page.
//		* Based on us.mi.AnnArborDistrictLibrary
//
// =============================================================================

#import "SOPAC2.h"


@implementation SOPAC2

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

//	[browser go: [Test fileURLFor: @"SOPAC/20110730_aadl.html"]];
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
	
	if ([scanner scanPassString: @"<h3>Checked-out Items"]
		&& [scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"patroninfo" intoElement: &element recursive: YES])
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
//		* Holds on same page as loans so need to scan pass the loans.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	if ([scanner scanPassString: @"<h3>Requested Items"]
		&& [scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"patroninfo" intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

@end