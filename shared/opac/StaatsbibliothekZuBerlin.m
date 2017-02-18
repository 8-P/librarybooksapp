#import "StaatsbibliothekZuBerlin.h"

@implementation StaatsbibliothekZuBerlin

- (BOOL) update
{
//	[browser go: catalogueURL];
	
//	URL *url = [browser linkToSubmitFormNamed: @"" entries: self.authenticationAttributes];
//	URL *url2 = [URL URLWithString: @"https://ausleihe.staatsbibliothek-berlin.de/opac/user.S"];
//	url2.attributes = url.attributes;
//
//	[browser go: url2];
//
//	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"OCLC/20120729_berlin_holds.html"]];
//	[browser go: [Test fileURLFor: @"OCLC/20120804_berlin_loans.html"]];
	
	[self go: @"medk"];
	[self parseLoans1];
	[self parseHoldsReadyForPickup1: YES];
	
	[self go: @"vorm"];
	[self parseHoldsReadyForPickup1: NO];

	[self go: @"best"];
	[self parseHoldsReadyForPickup1: YES];

	return YES;
}

- (void) go: (NSString *) func
{
	URL *url = [URL URLWithString: @"https://ausleihe.staatsbibliothek-berlin.de/opac/user.S"];
	NSMutableDictionary *attributes = self.authenticationAttributes;
	[attributes setObject: func forKey: @"FUNC"];
	url.attributes = attributes;
	
	[browser go: url];
}

// -----------------------------------------------------------------------------
//
// Parse loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (Berlin format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	[NSScannerSettings sharedSettings].columnCountMustMatch = NO;
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"dueDate",	@"Fällig",
		@"title",	@"Signatur",
		nil
	];
	if ([scanner scanPassString: @"<b>Entliehene Medien</b>"]
		&& [scanner scanNextElementWithName: @"table" regexValue: @"Signatur" intoElement: &element])
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
//		* The l
//
// -----------------------------------------------------------------------------
- (void) parseHoldsReadyForPickup1: (BOOL) ready
{
	[Debug log: @"Parsing holds (Berlin format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;
	
	[scanner scanPassHead];

	[NSScannerSettings sharedSettings].columnCountMustMatch = NO;
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"title",				@"Signatur",
		@"queueDescription",	@"Status",
		nil
	];
	
	if (ready == NO || [scanner scanPassString: @"<b>Abholbereite Medien</b>"])
	{
		if ([scanner scanNextElementWithName: @"table" regexValue: @"Signatur" intoElement: &element])
		{
			NSArray *columns	= [element.scanner analyseHoldTableColumns];
			NSArray *rows		= [element.scanner tableWithColumns: columns];
			
			if (ready)	[self addHoldsReadyForPickup: rows];
			else		[self addHolds: rows];
		}
	}
}

@end