// =============================================================================
//
// SISIS SunRise webOPAC by OCLC.
//
//		* http://www.oclc.org/sunrise/modules/opac/default.htm
//		* Holds not implemented.
//
// =============================================================================

#import "SISIS.h"

@implementation SISIS

- (BOOL) update
{
	// Visit the main page to get a cookie
	[browser go: [catalogueURL URLWithPath: @"start.do"]];
	[browser go: [browser.currentURL URLWithPath: @"userAccount.do?methodToCall=show&type=1"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	URL *holdsURL1 = [browser linkForLabel: @"Bestellungen"];
	URL *holdsURL2 = [browser linkForLabel: @"Vormerkungen"];
	
//	[browser go: [Test fileURLFor: @"SISIS/20111231_munster_loans.html"]];
//	[browser go: [Test fileURLFor: @"SISIS/20120225_munster_lots_loans.html"]];
	[self parseLoans1Page: 1];
	
//	holdsURL1 = [Test fileURLFor: @"SISIS/20120103_muster_bestellungen.html"];
//	holdsURL1 = [Test fileURLFor: @"SISIS/20120114_muster_holdsready.html"];
	if (holdsURL1)
	{
		[browser go: holdsURL1];
		[self parseHolds1];
	}

//	holdsURL2 = [Test fileURLFor: @"SISIS/20120103_muster_vormerkungen.html"];	
	if (holdsURL2)
	{
		[browser go: holdsURL2];
		[self parseHolds1];
	}
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1Page: (NSInteger) page
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
	
	// Look for the next page link
	scanner = browser.scanner;
	[scanner scanPassHead];
	if (page < 100 && [scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"box" intoElement: &element recursive: YES])
	{
		NSString *href = [element.scanner linkForLabel: [NSString stringWithFormat: @"%ld", (long) page + 1]];
		if (href)
		{
			[Debug log: @"Found next page link [%@]", href];
			[browser go: [browser.currentURL URLWithPath: href]];
			[self parseLoans1Page: page + 1];
		}
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
// Special parsing of the title cell.  The cell looks like:
//
//		<strong>Die deutschen Reichskreise in der Verfassung des alten Reiches und ihr Eigenleben</strong><br />
//		Dotzauer, Winfried<br />
//		3D 53405&nbsp;/&nbsp;3D 53405<br />
//		<a href="/Katalog/userAccount.do?methodToCall=renewalPossible&amp;actPos=0" onclick="return blockAction();">
//		<span class="textgruen">Eine Verlängerung ist möglich.</span></a>
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseLoanTitleCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<strong>(.*?)</strong>(<br />)?",		@"title",
		@"(.*?)<br />",							@"author",
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
// Special parsing of the due date cell.  The cell looks like:
//
//		<td>14.12.2011 - 12.01.2012<br />
//		Zentralbibliothek&nbsp;/&nbsp;Leihstelle / Buchabholung im EG</td>
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseLoanDueDateCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@".*?- (.*)", @"dueDate",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	return [scanner dictionaryUsingRegexMapping: mapping];
}

- (NSDictionary *) parseHoldStatusCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"(.*?)<br />",		@"queueDescription",
		@"(.*?)$",			@"pickupAt",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	NSDictionary *result = [scanner dictionaryUsingRegexMapping: mapping];
	if ([result count] == 0)
	{
		// Fall back to using the whole string as the title
		result = [NSDictionary dictionaryWithObject: [string stringWithoutHTML] forKey: @"queueDescription"];
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
	[browser go: [myAccountCatalogueURL URLWithPath: @"start.do"]];
	[browser go: [browser.currentURL URLWithPath: @"userAccount.do?methodToCall=show&type=1"]];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end