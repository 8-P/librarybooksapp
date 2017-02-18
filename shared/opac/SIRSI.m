// =============================================================================
//
// SIRSI catalogue system.
//
// Standard order:
//
//		1. Click on account page link
//		2. Click checkouts link
//		3. Get login prompt
//
// =============================================================================

#import "SIRSI.h"

@implementation SIRSI

- (BOOL) update
{
	[browser go: catalogueURL];
	
	// Logout first
	//
	//		* Usually this isn't needed.
	//		* Need it for us.pa.BucksCountyLibraryNetwork start from Oct 2011.
	//		  The newer systems could be keeping users logged in
	if ([browser clickLink: @"Logout"])
	{
		[Debug logError: @"Logged out"];
		[browser go: catalogueURL];
	}
	
	// Find the account page link.  There a many potential link names so
	// try them all until one matches
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
	// Find the link to the checkouts page
	if ([browser clickFirstLink: [self reviewLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find review checkouts page link"];
		return NO;
	}
	
	// The Yarra Plenty Regional Library implementation has two forms on the page.
	// The main form is named "accessform" and the secondary one in the
	// navigation bar is called "loginform"
	if ([browser submitFormNamed: @"accessform" entries: self.authenticationAttributes] == NO
		&& [browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20100309_fairfax_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20090621_main_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20100829_los_angeles_county_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20100821_santa_monica_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20101127_tln_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110115_niles_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110129_montgomery_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110403_northvancouver_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110827_montgomery_loans.html"]];

	[self parse];
	
	return YES;
}

- (void) parse
{
	[self parseLoans1];
	if (loansCount == 0) [self parseLoans2];
	if (loansCount == 0) [self parseLoans3];
	if (loansCount == 0) [self parseLoans4];

	[self parseHolds1];
	if (holdsCount == 0) [self parseHolds4];
	if (holdsCount == 0) [self parseHolds5];
}

- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	if (   [scanner scanNextElementWithName: @"form" attributeKey: @"id" attributeValue: @"renewitems" intoElement: &element]
		|| [scanner scanNextElementWithName: @"form" attributeKey: @"name" attributeValue: @"renewitems" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		if (loansTableColumns) columns = loansTableColumns;
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	if (   [scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"charges"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns = [NSArray arrayWithObjects: @"title", @"author", @"dueDate", nil];
		if (loansTableColumns) columns = loansTableColumns;
		NSArray *rows = [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Secondary loans parsing.
//
//		* Used by Niles Public Library District (us.il.NilesPublicLibraryDistrict)
//
// -----------------------------------------------------------------------------
- (void) parseLoans3
{
	[Debug log: @"Parsing loans (format 3)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	if ([scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"charges"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Secondary loans parsing.
//
//		* Used by Santa Cruz
//
// -----------------------------------------------------------------------------
- (void) parseLoans4
{
	[Debug log: @"Parsing loans (format 4)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// * "Description" is used by Santa Cruz library for the title/author
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"titleAndAuthor",	@"Description",
		nil
	];
	
	if (   [scanner scanPassString: @"Items checked out"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Holds (ready for pickup)
	if (   [scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"avail_holds"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHoldsReadyForPickup: rows];
	}
	
	// * The "Availability" column means queue position for the outstanding holds
	// * "Queue Position" is used by Calgary library
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"queuePosition", @"Availability",
		@"queuePosition", @"Queue Position",
		nil
	];

	// Holds (just outstanding or combined holds list)
	if (   [scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"holds"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Matching holds parsing for parseLoans4.
//
// -----------------------------------------------------------------------------
- (void) parseHolds4
{
	[Debug log: @"Parsing holds (format 4)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"titleAndAuthor",		@"Description",
		@"queueDescription",	@"Request List Information",
		nil
	];
	
	if (   [scanner scanPassString: @"Titles on request"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Based on format in CLEVNET.
//
//		* Column called Available that has "Y" when ready and empty otherwise.
//
// -----------------------------------------------------------------------------
- (void) parseHolds5
{
	[Debug log: @"Parsing holds (format 5)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"queuePosition",		@"Position in Queue",
		@"readyForPickup",		@"Available",
		nil
	];
	
	// Holds (just outstanding or combined holds list)
	if (   [scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"requests"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObject: @"Position in Queue"] delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The various account link labels.
//
// -----------------------------------------------------------------------------
- (NSArray *) accountLinkLabels
{
	return [NSArray arrayWithObjects:
		@"My Account",
		@"Your Account",
		@"My Library Card",
		@"my.account",
		@"My Library Record",			// au.nsw.MooreCollegeLibrary
		@"RBUSERV.gif",
		@"Account Info/Renew",			// us.md.AnneArundelCountyPublicLibrary
		nil
	];
}

// -----------------------------------------------------------------------------
//
// THe various review my account link labels.
//
// -----------------------------------------------------------------------------
- (NSArray *) reviewLinkLabels
{
	return [NSArray arrayWithObjects: 
		@"User Status Inquiry",
		@"Review My Account",
		@"Review Your Account",
		@"Review My Card",
		@"Review Checkouts",
		@"Renew materials/manage holds",
		@"Checkouts",
		@"ACCOUNT SUMMARY",
		@"SUMMARY (holds, bills)",			// ca.bc.NorthVancouverCityLibrary
		@"View My Record",					// au.nsw.MooreCollegeLibrary
		@"Review/Renew",					// us.ct.CONNECT
		@"Renew materials",					// us.ca.CountyOfLosAngelesPublicLibrary
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
	[browser go: myAccountCatalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return nil;
	}
	
	if ([browser clickFirstLink: [self reviewLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find review account page link"];
		return nil;
	}
	
	return [browser linkToSubmitFormNamed: @"accessform" entries: self.authenticationAttributes];
}

@end