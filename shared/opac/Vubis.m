// =============================================================================
//
// Vubis.
//
// =============================================================================

#import "Vubis.h"
#import "HTMLTidySettings.h"

@implementation Vubis

- (BOOL) update
{
	[browser deleteCookies: [catalogueURL URLWithPath: @"/"]];

	// The page has invalid HTML.  Use a prefilter to remove the offending code
	HTMLTidySettings *htmlTidySettings = [HTMLTidySettings sharedSettings];
	htmlTidySettings.prefilterBlock = ^(NSString *html)
	{
		html = [html stringByDeletingOccurrencesOfRegex: @"<HEAD>[\r\n]*</HEAD>[\r\n]*<TITLE></TITLE>[\r\n]*</HEAD>"];
		return html;
	};

	// The site uses frames
	[browser focusOnFrameNamed: @"Body"];
	
	[browser go: [catalogueURL URLWithPath: @"Pa.csp"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	URL *loansURL = [browser linkForLabel: @"My loans, with possibility of renewal"];
	URL *holdsURL = [browser linkForLabel: @"My reservations"];
	
//	[browser go: [Test fileURLFor: @"Amlib/20110713_kingston_loans.html"]];
	
	// Loans
	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1];
	}
    
    // Holds
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHolds1];
	}
	
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
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"class=\"listhead\"" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
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

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseHoldExpiryDateCell:", @"Available until",
		nil
	];

	[scanner scanPassHead];

	if ([scanner scanNextElementWithName: @"table" regexValue: @"class=\"listhead\"" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObject: @"listhead"] delegate: self];
		[self addHolds: rows];
	}
}

- (NSDictionary *) parseHoldExpiryDateCell: (NSString *) string
{
	string = [[string stringWithoutHTML] stringByTrimmingWhitespace];
	if ([string length] > 0)
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:
			string, @"expiryDate",
			@"yes", @"readyForPickup",
			nil
		];
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: [myAccountCatalogueURL URLWithPath: @"Logoff.csp"]];

	// The page has invalid HTML.  Use a prefilter to remove the offending code
	HTMLTidySettings *htmlTidySettings = [HTMLTidySettings sharedSettings];
	htmlTidySettings.prefilterBlock = ^(NSString *html)
	{
		html = [html stringByDeletingOccurrencesOfRegex: @"<HEAD>[\r\n]*</HEAD>[\r\n]*<TITLE></TITLE>[\r\n]*</HEAD>"];
		return html;
	};

	// The site uses frames
	[browser focusOnFrameNamed: @"Body"];
	
	[browser go: [myAccountCatalogueURL URLWithPath: @"Pa.csp"]];

	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end