// =============================================================================
//
// The Public Library of Cincinnati and Hamilton County
//
//		* Get password prompt after clicking "My Account" link.
//		* STOPPED USING on 2012-08-04 because the library switch to Millennium.
//
// =============================================================================

#import "PublicLibraryOfCincinnatiAndHamiltonCounty.h"

@implementation PublicLibraryOfCincinnatiAndHamiltonCounty

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find review account page link"];
		return NO;
	}
	
	if ([browser submitFormNamed: @"accessform" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20110521_cincinnati_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110528_cincinnati_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110601_cincinnati_loans.html"]];
	[self parse];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Custom holds parsing.
//
//		* The holds not ready for pickup format doesn't match the standard
//		  parser.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (Cincinnati format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Holds (ready for pickup)
	if ([scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"avail_holds"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHoldsReadyForPickup: rows];
	}

	// Holds
	if ([scanner scanPassElementWithName: @"h4" attributeKey: @"id" attributeValue: @"holds"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return nil;
	}

	return [browser linkToSubmitFormNamed: @"accessform" entries: self.authenticationAttributes];
}

@end