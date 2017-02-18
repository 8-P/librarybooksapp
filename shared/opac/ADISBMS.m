// =============================================================================
//
// aDIS/BMS by |a|S|tec|
//
// Demo site here:
// https://www.astec.de/aDISWeb/app?service=direct/0/Home/$DirectLink&sp=S127.0.0.1:5103&sp=SBD00000000&sp=SEN
//
//		* Can't get to download holds.  There looks like some server side
//		  state
//	
// =============================================================================

#import "ADISBMS.h"

@implementation ADISBMS

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser clickLink: @"User Account"] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

	URL *loansURL				= [browser linkForLabel: @"Display Checked-Out Items"];
	URL *holdsURL				= [browser linkForLabel: @"Display Ordered Items"];	
	URL *holdsReadyForPickupURL = [browser linkForLabel: @"Display Reserved Item"];
	
	// Loans
	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1];
	}
	
	// Holds ready for pickup
	if (holdsReadyForPickupURL)
	{
		[browser go: holdsReadyForPickupURL];
		[self parseHoldsReadyForPickup1: YES];
	}

	// Holds not yet available
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHoldsReadyForPickup1: NO];
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
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"rTable_table" intoElement: &element])
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
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	// Holds ready for pickup
	while ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"rTable_table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		
		if (readyForPickup)	[self addHoldsReadyForPickup: rows];
		else				[self addHolds:               rows];
		
		if (loansCount > 0) break;
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
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