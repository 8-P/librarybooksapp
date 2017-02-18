// =============================================================================
//
// CAFE (Catalog Access For Everyone), WI, USA
// Libraries in Waukesha County.  Includes Waukesha Public Library.
//
//		* It is a SIRSI system but has no "Review Card" link.
//		* Loans parsing is different.
//
// =============================================================================

#import "CAFE.h"

@implementation CAFE

- (BOOL) update
{
	[browser go: catalogueURL];
	
	// Find the account page link
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug log: @"Can't find account page link"];
		return NO;
	}
	
	// Login
	if ([browser submitFormNamed: @"accessform" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20100410_cafe_loans.html"]];
	[self parseLoans1];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Special table parsing.
//
//		* The loans table doesn't have headers so can't do autocolumn detection.
//		* Title/author parsing is special too.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans/holds (CAFE format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Loans
	if ([scanner scanNextElementWithName: @"form" attributeKey: @"id" attributeValue: @"renewitems" intoElement: &element])
	{
		if ([element.scanner scanNextElementWithName: @"table" intoElement: &element])
		{
			NSArray *columns	= [NSArray arrayWithObjects: @"", @"parseTitleAndAuthor:", @"dueDate", nil];
			NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
			[self addLoans: rows];
		}
	}
}

- (void) parseHolds1
{
	[Debug log: @"Parsing loans/holds (CAFE format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];

	// Holds
	if ([scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"holds"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing for the title/author cell.
//
//		* Title/author separator is &nbsp;&nbsp;:
//		* Example cell string:
//			Buckaroo Banzai : return of the screw&nbsp;&nbsp;\n
//			Rauch, Earl Mac, 1949-
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseTitleAndAuthor: (NSString *) string
{
	NSString *title		= nil;
	NSString *author	= nil;
	[string splitStringOnLast: @"&nbsp;&nbsp;" intoLeft: &title intoRight: &author];

	return [NSDictionary dictionaryWithObjectsAndKeys:
		[title stringWithoutHTML],		@"title",
		[author stringWithoutHTML],		@"author",
		nil
	];
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: catalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug log: @"Can't find account page link"];
		return nil;
	}
	
	return [browser linkToSubmitFormNamed: @"accessform" entries: self.authenticationAttributes];
}

@end