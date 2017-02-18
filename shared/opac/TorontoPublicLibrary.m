// =============================================================================
//
// Toronto Public Library, ON, Canada.
//
//		* It is a SIRSI system but it has a custom login and loan/hold pages.
//		* They updated their website around 2010-08-15.
//		* Need to Sign Out first.
//
// =============================================================================

#import "TorontoPublicLibrary.h"

@implementation TorontoPublicLibrary

- (BOOL) update
{
	[browser go: catalogueURL];
	[browser clickLink: @"Sign Out"];
	[browser go: catalogueURL];
	
	[browser go: catalogueURL];
	[browser submitFormNamed: @"form_signin" entries: self.authenticationAttributes];
	[self authenticationOK];
	
	// Work around, the login doesn't redirect to the account page properly
	[browser go: catalogueURL];
	
	if ([[browser.scanner string] hasSubString: @"Sign Out"] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	
	if ([[browser.scanner string] hasSubString: @"Some services are unavailable at this time"])
	{
		[Debug logError: @"Catalogue offline for maintenance"];
		return NO;
	}

//	[browser go: [Test fileURLFor: @"SIRSI/20100919_tpl_loans.html"]];
	[self parseLoans1];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// There are "id" attributes that make it easy to find the data.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (Toronto format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Loans
	if ([scanner scanNextElementWithName: @"tbody" attributeKey: @"id" attributeValue: @"renewcharge" intoElement: &element])
	{
		NSArray *columns = [NSArray arrayWithObjects: @"", @"titleUptoSlash", @"", @"dueDate", nil];
		NSArray *rows = [element.scanner tableWithColumns: columns ignoreRows: nil];
		[self addLoans: rows];
	}
}

- (void) parseHolds1
{
	[Debug log: @"Parsing holds (Toronto format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// Holds available for pickup
	if ([scanner scanNextElementWithName: @"tbody" attributeKey: @"id" attributeValue: @"tblAvail" intoElement: &element])
	{
		NSArray *columns = [NSArray arrayWithObjects: @"", @"titleUptoSlash", @"pickupAt", nil];
		NSArray *rows = [element.scanner tableWithColumns: columns ignoreRows: nil];
		[self addHoldsReadyForPickup: rows];
	}

	// Holds on its way for pickup
	if ([scanner scanNextElementWithName: @"tbody" attributeKey: @"id" attributeValue: @"tblIntr" intoElement: &element])
	{
		NSArray *columns = [NSArray arrayWithObjects: @"", @"titleUptoSlash", @"pickupAt", @"queueDescription", nil];
		NSArray *rows = [element.scanner tableWithColumns: columns ignoreRows: nil];
		[self addHolds: rows];
	}
	
	// Holds
	if ([scanner scanNextElementWithName: @"tbody" attributeKey: @"id" attributeValue: @"tblHold" intoElement: &element])
	{
		NSArray *columns = [NSArray arrayWithObjects: @"", @"title", @"queuePosition", @"pickupAt", @"", @"queueDescription", nil];
		NSArray *rows = [element.scanner tableWithColumns: columns ignoreRows: nil];
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
	[browser go: catalogueURL];
	if ([browser clickLink: @"Sign Out"])
	{
		[browser go: catalogueURL];
	}
	return [browser linkToSubmitFormNamed: @"form_signin" entries: self.authenticationAttributes];
}

@end