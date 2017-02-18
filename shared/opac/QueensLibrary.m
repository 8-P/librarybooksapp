// =============================================================================
//
// Queens Library, NY, USA
//
//		* VTLS Chameleon iPortal.
//		* Customised login.
//
// =============================================================================

#import "QueensLibrary.h"

@implementation QueensLibrary

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/logout"]];
	[browser go: catalogueURL];

	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	[browser go: [browser.currentURL URLWithPath: @"/my-account"]];

//	[browser go: [Test fileURLFor: @"Chameleon/20100906_queens_loans.html"]];
//	[browser go: [Test fileURLFor: @"Chameleon/20120303_queens_loans.html"]];

	[self parseLoans1];
	
	[browser clickLink: @"Requests"];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Parse loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (Queens format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanPassElementWithName: @"h2" regexValue: @"Checked Out Items"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (Queens format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"queuePosition", @"Queue",
		nil
	];
	
	if ([scanner scanPassElementWithName: @"h2" regexValue: @"Requested Items"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Custom authentication attributes.
//
//		* Need to add in op="Log in".
//
// -----------------------------------------------------------------------------
- (NSMutableDictionary *) authenticationAttributes
{
	NSMutableDictionary *d = super.authenticationAttributes;
	[d setObject: @"Log in" forKey: @"op"];
	
	return d;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: [myAccountCatalogueURL URLWithPath: @"/logout"]];
	[browser go: myAccountCatalogueURL];
	
	URL *url = [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
	url.nextURL = [browser.currentURL URLWithPath: @"/my-account"];
	
	return url;
}

- (BOOL) myAccountEnabled
{
	return [URL defaultBrowserIsSafari];
}

@end