// =============================================================================
//
// NetOpacs by Amlib.
//
// =============================================================================

#import "Amlib.h"

@implementation Amlib

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"Amlib/20110713_kingston_loans.html"]];
//	[browser go: [Test fileURLFor: @"Amlib/20110717_hobsonsbay_holds.html"]];
//	[browser go: [Test fileURLFor: @"Amlib/20110730_hornsby_loans.html"]];
//	[browser go: [Test fileURLFor: @"Amlib/20110814_freemantle_loans.html"]];
	
	[self parseLoans1];
	if (loansCount == 0) [self parseLoans2];
	
	[self parseHolds1];
	if (holdsCount == 0) [self parseHolds2];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans format 1.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"fieldset" regexValue: @"<legend>Current Loans</legend>" intoElement: &element]
		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Loans format 2.
//
//		* Used by the older versions.
//		* The "Current Loans" text can be in a <strong></strong>, <a name=""></a> or
//		  <h5></h5>.
//
// -----------------------------------------------------------------------------
- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if (   [scanner scanPassString: @"<strong>Current Loans</strong>"]
		|| [scanner scanPassString: @"<a name=\"loan\">Current Loans</a>"]
		|| [scanner scanPassString: @"<h5>Current Loans</h5>"]
		|| [scanner scanPassString: @"<h3>Current Loans</h3>"])
	{
		if ([scanner scanNextElementWithName: @"table" intoElement: &element])
		{
			NSArray *columns	= [element.scanner analyseLoanTableColumns];
			NSArray *rows		= [element.scanner tableWithColumns: columns];
			[self addLoans: rows];
		}
	}
}

// -----------------------------------------------------------------------------
//
// Holds format 1.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	if ([scanner scanNextElementWithName: @"fieldset" regexValue: @"<legend>Current Reservations</legend>" intoElement: &element]
		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObject: @"Queue Position"]];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds format 2.
//
//		* Used by the older versions.
//		* The table is present even if there is not data.
//
// -----------------------------------------------------------------------------
- (void) parseHolds2
{
	[Debug log: @"Parsing holds (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	if (   [scanner scanPassString: @"<strong>Current Reservations</strong>"]
		|| [scanner scanPassString: @"<a name=\"res\">Current Reservations</a>"]
		|| [scanner scanPassString: @"<h5>Current Reservations</h5>"]
		|| [scanner scanPassString: @"<h3>Current Reservations</h3>"])
	{
		if ([scanner scanNextElementWithName: @"table" intoElement: &element])
		{
			NSArray *columns	= [element.scanner analyseHoldTableColumns];
			NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObject: @"Queue Position"]];
			[self addHolds: rows];
		}
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end