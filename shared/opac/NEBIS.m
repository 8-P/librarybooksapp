// =============================================================================
//
// NEBIS
//
// =============================================================================

#import "NEBIS.h"

@implementation NEBIS

- (BOOL) update
{
	[browser go: catalogueURL];

	// Deal with JavaScript redirect to SSO page
	NSString *url;
	if ([browser.scanner scanFromString: @"var url = '" upToString: @"'" intoString: &url])
	{
		[Debug log: @"Following redirect 1 [%@]", url];
		[browser go: [URL URLWithString: url]];
	}
	
	[browser clickLink: @"Return from Check SSO"];
	
	if ([browser.scanner scanRegex: @"(?m)^\\s*var url = '(.*?)'" capture: 1 intoString: &url])
	{
		url = [url stringByReplacingOccurrencesOfString: @"LOGIN_PAGE" withString: @"bor-info"];
	
		[Debug log: @"Following redirect 3 [%@]", url];
		[browser go: [URL URLWithString: url]];
	}
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

	[browser clickLink: @"Click here to continue"];

//	[browser go: [Test fileURLFor: @"NEBIS/20120830_account.html"]];
	
	NSString *loansURL = [browser.scanner linkForHrefRegex: @"func=bor-loan&amp;adm_library=EAD50"];
	loansURL = [loansURL stringByDeletingOccurrencesOfString: @"javascript:replacePage('"];
	loansURL = [loansURL stringByDeletingOccurrencesOfString: @"')"];
	
	NSString *holdsURL = [browser.scanner linkForHrefRegex: @"func=bor-hold&amp;adm_library=EAD50"];
	holdsURL = [loansURL stringByDeletingOccurrencesOfString: @"javascript:replacePage('"];
	holdsURL = [loansURL stringByDeletingOccurrencesOfString: @"')"];
	
//	[browser go: [Test fileURLFor: @"SISIS/20111231_munster_loans.html"]];

	// Loans
	[browser go: [URL URLWithString: loansURL]];
	[self parseLoans1];
	
	// Holds
	[browser go: [URL URLWithString: holdsURL]];
	[self parseHolds1];
	
	return YES;
}

- (NSMutableDictionary *) authenticationAttributes
{
	NSMutableDictionary *authenticationAttributes = super.authenticationAttributes;
	[authenticationAttributes setObject: @"login" forKey: @"func"];
	
	return authenticationAttributes;
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
	
	scannerSettings.ignoreTableHeaderCells = NO;
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseLoanTitleCell:",		@"Titel",
		@"parseLoanDueDateCell:",	@"Leihfrist",
		nil
	];
	
	if ([scanner scanPassString: @"<h2>Ausleihen</h2>"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
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

	scannerSettings.ignoreTableHeaderCells = NO;
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseLoanTitleCell:",		@"Titel",
		@"parseHoldStatusCell:",	@"Zweigstelle",
		nil
	];

	if (([scanner scanPassString: @"<h2>Bestellungen</h2>"] || [scanner scanPassString: @"<h2>Vormerkungen</h2>"])
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])

	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObject: @"Leihfrist,&nbsp;Zweigstelle"] delegate: self];
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
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end