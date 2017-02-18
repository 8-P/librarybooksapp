// =============================================================================
//
// Milleninum catalogue system.
//
// =============================================================================

#import "Millenium.h"
#import "HTMLTidySettings.h"

@implementation Millenium

- (BOOL) update
{
	// The new Encore login pages have bad HTML that break the form parser
	//		* They have hidden form fields outside the <form/> block
	HTMLTidySettings *htmlTidySettings = [HTMLTidySettings sharedSettings];
	[htmlTidySettings.noTidyURLs addObject: @"/iii/cas/login"];

	[catalogueURL deleteAssociatedCookies];
	[browser go: catalogueURL];

	// Log in
	//		* The login form name is normally "patform" but some libraries like
	//		  NYPL have their own custom form
	//		* Some libraries don't have a name for the login form (e.g. Minuteman)
	NSString *loginFormName = [properties objectForKey: @"LoginFormName"];
	if (loginFormName == nil) loginFormName = @"AUTO";
	if ([browser submitFormNamed: loginFormName entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to find login form"];
		return NO;
	}
	[self authenticationOK];
	
	// Handle URLS with IIITICKET in the path.  This was first encountered in
	// Berkely Public Library.  So need to work around URLs like
	// http://.../patroninfo~S11/IIITICKET?ticket=ST-1655-NciJ7moUsFfYdTFWADuD7A2Ev7jQEzpWDgq-20
	NSString *urlString = [browser.currentURL absoluteString];
	if ([urlString hasSubString: @"/IIITICKET"])
	{
		urlString = [urlString stringByDeletingOccurrencesOfRegex: @"/IIITICKET\?.*$"];
		[browser go: [URL URLWithFormat: @"%@/items", urlString]];
	}
	
	// The site normally starts in the items screen.  Strip off that part of the URL
	urlString = [browser.currentURL absoluteString];
	urlString = [urlString stringByDeletingOccurrencesOfString: @"/items"];
	urlString = [urlString stringByDeletingOccurrencesOfString: @"/holds"];
	urlString = [urlString stringByDeletingOccurrencesOfString: @"/top"];
	urlString = [urlString stringByDeletingOccurrencesOfString: @"/overdues"];
	urlString = [urlString stringByDeletingOccurrencesOfString: @"/mylists"];
	
	// The URLs a quite predictable so we just formulate them.
	// The URLs are look like: http://library.provlib.org/patroninfo~S1/1131862/items
	URL *itemsURL = [URL URLWithFormat: @"%@/items", urlString];
	URL *holdsURL = [URL URLWithFormat: @"%@/holds", urlString];

	// Loans
	[browser go: itemsURL];
//	[browser go: [Test fileURLFor: @"Millenium/items2.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20090824_oslri_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20090905_minuteman_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20090912_minuteman_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20090914_cadl_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20100317_multnomah_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20100411_multinomah_lotsof_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20100819_peninsula_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20101114_nashville_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20110327_chapelhill_loans.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20110403_houston_loans.html"]];
	[self parseLoans1];

	// Holds
	[browser go: holdsURL];
//	[browser go: [Test fileURLFor: @"Millenium/holds1.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20090905_minuteman_holds.html"]];
//	[browser go: [Test fileURLFor: @"Millenium/20101018_sfpl_holds.html"]];
	[self parseHolds1];
	
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
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"CHECKED OUT" intoElement: &element])
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
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element = nil;

	[scanner scanPassHead];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"STATUS" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
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
	HTMLTidySettings *htmlTidySettings = [HTMLTidySettings sharedSettings];
	[htmlTidySettings.noTidyURLs addObject: @"/iii/cas/login"];
	
	[catalogueURL deleteAssociatedCookies];
	[browser go: myAccountCatalogueURL];
	
	NSString *loginFormName = [properties objectForKey: @"LoginFormName"];
	if (loginFormName == nil) loginFormName = @"AUTO";
	return [browser linkToSubmitFormNamed: loginFormName entries: self.authenticationAttributes];
}

@end