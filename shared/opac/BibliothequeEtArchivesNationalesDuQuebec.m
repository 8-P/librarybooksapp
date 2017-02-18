// =============================================================================
//
// Bibliothèque et archives nationales du Québec
//
// =============================================================================

#import "BibliothequeEtArchivesNationalesDuQuebec.h"

@implementation BibliothequeEtArchivesNationalesDuQuebec

- (BOOL) update
{
	// We want the mobile site.  The normal site uses too much AJAX and is
	// impossible to parse
	[browser useMobileUserAgent];

	[browser go: catalogueURL];

	if ([browser.scanner.string hasSubString: @"Se déconnecter"])
	{
		[Debug log: @"Logged out"];
		
		// The web site opens a frame and opens all these links to log out
		[browser go: [URL URLWithString: @"https://www.banq.qc.ca/extranetca/Shibboleth.sso/Logout"]];
		[browser go: [URL URLWithString: @"https://iris.banq.qc.ca/Shibboleth.sso/Logout"]];
		[browser go: [URL URLWithString: @"https://www.banq.qc.ca/grandextranet/Shibboleth.sso/Logout"]];
		[browser go: [URL URLWithString: @"https://sqtd.banq.qc.ca/Shibboleth.sso/Logout"]];
		[browser go: [URL URLWithString: @"https://www.banq.qc.ca/Shibboleth.sso/Logout"]];
		
		[browser go: catalogueURL];
	}
	
	// Skip over the you do not have JavaScript warning page
	if ([[browser.scanner string] hasSubString: @"Since your browser does not support JavaScript"])
	{
		[browser submitFirstForm];
	}
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Could not find login form"];
	}
	else
	{
		[self authenticationOK];
	}
	
	// Skip over the you do not have JavaScript warning page
	if ([[browser.scanner string] hasSubString: @"Since your browser does not support JavaScript"])
	{
		[browser submitFirstForm];
	}
	
	// The library gives 500 error pages at night time.  Don't try and parse the
	// error page
	if ([[browser.scanner string] hasSubString: @"HTTP Status 500"])
	{
		[Debug logError: @"Catalogue offline"];
		return NO;  
	}
	
//	[browser go: [Test fileURLFor: @"Ungrouped/20111126_quebec_loans.html.html"]];
	
	[self parseLoans1];
	[self parseHolds1];
	
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

	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"(.*?)<br />",				@"titleAndAuthor",
		@"échéance(.*?)<br />",		@"dueDate",
		nil
	];
	
	if ([scanner scanPassString: @"<strong>Prêts en cours</strong>"]
		&& [scanner scanNextElementWithName: @"ul" intoElement: &element])
	{
		HTMLElement *element2;
		NSMutableArray *rows = [NSMutableArray array];
		while ([element.scanner scanNextElementWithName: @"li" intoElement: &element2])
		{
			NSDictionary *row = [element2.scanner dictionaryUsingRegexMapping: mapping];
			[rows addObject: row];
		}
		
		[self addLoans: rows];
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

	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"\\(.*?\\) (.*?)\\n", @"titleAndAuthor",
		nil
	];
	
	if ([scanner scanPassString: @"<strong>Réservations</strong>"]
		&& [scanner scanNextElementWithName: @"ul" intoElement: &element])
	{
		HTMLElement *element2;
		NSMutableArray *rows = [NSMutableArray array];
		while ([element.scanner scanNextElementWithName: @"li" intoElement: &element2])
		{
			NSDictionary *row = [element2.scanner dictionaryUsingRegexMapping: mapping];
			[rows addObject: row];
		}
		
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
//		* If the user is already logged in the linkToSumitFormNamed won't work and
//		  will return nil.  When this happens just return the account URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser useMobileUserAgent];
	[browser go: myAccountCatalogueURL];
	URL *url = [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
	return (url) ? url : myAccountCatalogueURL;
}

@end