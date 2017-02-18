// =============================================================================
//
// VuFind (open source system)
//
// =============================================================================

#import "VuFind.h"

@implementation VuFind

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"MyResearch/Logout"]];
	[browser go: [catalogueURL URLWithPath: @"MyResearch/Home"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"VuFind/20130430_philadelphia_loans.html"]];
//	[browser go: [Test fileURLFor: @"VuFind/20130907_winnefox_loans.html"]];
//	[browser go: [Test fileURLFor: @"VuFind/20140118_douglas_loans.html"]];
	[self parseLoans1];
	if (loansCount == 0) [self parseLoans2];
	if (loansCount == 0) [self parseLoans3];
	
	[self parseHolds1];
	if (holdsCount == 0) [self parseHolds2];
	
	// us.wi.WinnefoxLibrarySystem has a separate holds page
	if (holdsCount == 0)
	{
//		[browser go: [Test fileURLFor: @"VuFind/20130922_winnefox_holds.html"]];
//		[browser go: [Test fileURLFor: @"VuFind/20140118_douglas_holds.html"]];
		[browser go: [catalogueURL URLWithPath: @"MyResearch/Holds"]];
		[self parseHolds1];
		if (holdsCount == 0) [self parseHolds2];
		if (holdsCount == 0) [self parseHolds3];
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
	
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleCell:", @"Title",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Times Renewed" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Loans 2.
//
//	* Based on Winnefox us.wi.WinnefoxLibrarySystem.
//
// -----------------------------------------------------------------------------
- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a.*?class=\"title\".*?>(.*?)</a>",	@"title",
		@"by: <a.*?>(.*?)</a>",					@"author",
		@"<strong>Due Date: (.*?)</strong>",	@"dueDate",
		nil
	];
	
	NSMutableArray *rows = [NSMutableArray array];
	if ([scanner scanNextElementWithName: @"ul" attributeKey: @"class" attributeValue: @"recordSet" intoElement: &element recursive: YES])
	{
		scanner = element.scanner;
		while ([scanner scanNextElementWithName: @"li" intoElement: &element])
		{
			[Debug logDetails: element.value withSummary: @"Parsing row"];
			NSMutableDictionary *row = [[[element.scanner dictionaryUsingRegexMapping: mapping] mutableCopy] autorelease];
			[rows addObject: row];
		}
	}
	
	[self addLoans: rows];
}

// -----------------------------------------------------------------------------
//
//
//
// -----------------------------------------------------------------------------
- (void) parseLoans3
{
	[Debug log: @"Parsing loans (format 3)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleCell2:", @"Title",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Wait List" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
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
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleCell:", @"Title",
		@"queuePosition",	@"Place in Line",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"Pick Up Location" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds2
{
	[Debug log: @"Parsing holds (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleCell:", @"Title",
		@"pickupAt",		@"Pickup Library",
		@"expiryDate",		@"Pickup by",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"holdDetails" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds3
{
	[Debug log: @"Parsing holds (format 3)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseTitleCell2:",	@"Title",
		@"pickupAt",			@"Pickup",
		@"expiryDate",			@"Expires",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"holdsTableavailable" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHoldsReadyForPickup: rows];
	}
	
	if ([scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"holdsTableunavailable" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: nil delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing of the title cell.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseTitleCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a .*?>(.*?)</a>",		@"title",
		@"By: <a .*?>(.*?)</a>",	@"author",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	NSDictionary *result = [scanner dictionaryUsingRegexMapping: mapping];
	if ([result count] == 0)
	{
		// Fall back to using the whole string as the title
		result = [NSDictionary dictionaryWithObject: [string stringWithoutHTML] forKey: @"title"];
	}
	
	return result;
}

- (NSDictionary *) parseTitleCell2: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a .*? class=\"title\">(.*?)</a>",	@"title",
		@"by <a .*?>(.*?)</a>",					@"author",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	NSDictionary *result = [scanner dictionaryUsingRegexMapping: mapping];
	if ([result count] == 0)
	{
		// Fall back to using the whole string as the title
		result = [NSDictionary dictionaryWithObject: [string stringWithoutHTML] forKey: @"title"];
	}
	
	return result;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: [catalogueURL URLWithPath: @"MyResearch/Logout"]];
	[browser go: [catalogueURL URLWithPath: @"MyResearch/Home"]];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end