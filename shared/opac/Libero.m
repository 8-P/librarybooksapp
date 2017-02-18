// =============================================================================
//
// CARLweb
//
// Original implementation based on Woollahra Library, NSW, Australia.
//
// Notes:
//		* Based on Libero V5.5 sp 5.
//
// =============================================================================

#import "Libero.h"

@implementation Libero

- (BOOL) update
{
	[browser go: catalogueURL];
	[browser clickLink: @"Member Services"];
	
	if ([browser submitFormNamed: @"display" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"Libero/20101018_murray.html"]];
	[self parseLoans1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Parse loans and holds.
//
// Notes:
//		* The first row in the loans row is a <th> and the automatic column
//		  scanner is confused by it.  Therefore the columns need to be hardcoded.
//		* Sections in this order:
//				* Issues items
//				* Items Waiting collection
//				* Reserved items
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;
	
	// Loans
	if ([scanner scanNextElementWithName: @"fieldset" attributeKey: @"id" attributeValue: @"issued_items" intoElement: &element])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"parseLoanTitleCell:", @"author", @"dueDate", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
	
	// Holds ready for pickup
	if ([scanner scanNextElementWithName: @"fieldset" attributeKey: @"id" attributeValue: @"hold_items_flds" intoElement: &element])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"", @"title", @"author", @"", @"pickupAt", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHoldsReadyForPickup: rows];
	}
	
	// Holds waiting
	if ([scanner scanNextElementWithName: @"fieldset" attributeKey: @"id" attributeValue: @"reserved_items_flds" intoElement: &element])
	{
		NSArray *columns	= [NSArray arrayWithObjects: @"queuePosition", @"", @"title", @"author", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing of the loans title cell.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseLoanTitleCell: (NSString *) string
{
	NSString *title = [string stringUptoFirst: @"<br />"];
	title			= [title stringWithoutHTML];
	
	return [NSDictionary dictionaryWithObject: title forKey: @"title"];
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	[browser clickLink: @"Member Services"];
	return [browser linkToSubmitFormNamed: @"display" entries: self.authenticationAttributes];
}

@end