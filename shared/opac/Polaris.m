// =============================================================================
//
// Polaris
//
// =============================================================================

#import "Polaris.h"

@implementation Polaris

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"logon.aspx?logoff=1&mobile=1"]];
	[browser go: [catalogueURL URLWithPath: @"patronaccount/default.aspx"]];
	
	// us.oh.DaytonMetroLibrary has multiple submit buttons so the buttonSubmit
	// parameter does get detected.  We force it here
	NSMutableDictionary *authenticationAttributes = self.authenticationAttributes;
	[authenticationAttributes setObject: @"Log In" forKey: @"buttonSubmit"];
	
	if ([browser submitFormNamed: @"AUTO" entries: authenticationAttributes] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	URL *loansURL = [catalogueURL URLWithPath: @"patronaccount/itemsout.aspx"];
	URL *holdsURL = [catalogueURL URLWithPath: @"patronaccount/requests.aspx"];
	
//	loansURL = [Test fileURLFor: @"Polaris/20120529_grandview_loans.html"];
//	loansURL = [Test fileURLFor: @"Polaris/20101231_easicat_loans.html"];
//	loansURL = [Test fileURLFor: @"Polaris/201209809_pgcmls_loans.html"];
	[browser go: loansURL];
	[self parseLoans1];

//	holdsURL = [Test fileURLFor: @"Polaris/20120529_grandview_holds.html"];
//	holdsURL = [Test fileURLFor: @"Polaris/20110101_easicat_holds.html"];
//	holdsURL = [Test fileURLFor: @"Polaris/20110106_pgcmls_holds.html"];
//	holdsURL = [Test fileURLFor: @"Polaris/20110109_lebanon_holds.html"];
	[browser go: holdsURL];
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
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if (   [scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"datagridItemsOut" intoElement: &element recursive: YES]
		|| [scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"patrongrid" intoElement: &element recursive: YES])
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
//		* Need custom title parsing to break up the title/author.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"parseHoldTitleCell:",	@"Title",
		@"queueDescription",	@"Status",
		@"queuePosition",		@"Hold Position",
		nil
	];
	
	if (   [scanner scanNextElementWithName: @"table" attributeKey: @"id" attributeValue: @"datagridRequests" intoElement: &element recursive: YES]
		|| [scanner scanNextElementWithName: @"table" attributeKey: @"class" attributeValue: @"patrongrid" intoElement: &element recursive: YES])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *ignoreRows	= [NSArray arrayWithObjects: @"TableHeader", nil];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: ignoreRows delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Special parsing of the holds title cell.  The cell looks like:
//
//		<span id="datagridRequests__ctl2_labelTitle">
//			<a href="http://www.easicat.net/polaris/view.aspx?cn=760239">How I got over</a><br />
//			&nbsp;&nbsp;&nbsp;<span class='HoldsAuthor'>by Roots (Musical group)</span>
//		</span>
//
//	Note:
//
//		* The class='HoldsAuthor' uses *single* quotes.
//		* Need to remove the "by" prefix on the author.
//		* Lebanon County Library System doesn't use this fancy format.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseHoldTitleCell: (NSString *) string
{
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a.*?>(.*?)</a>",								@"title",
		@"<span.*?HoldsAuthor.*?>(?:by )?(.*?)</span>",	@"author",
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
	[browser go: [catalogueURL URLWithPath: @"logon.aspx?logoff=1&mobile=1"]];
	[browser go: [catalogueURL URLWithPath: @"patronaccount/default.aspx"]];
	
	NSMutableDictionary *authenticationAttributes = self.authenticationAttributes;
	[authenticationAttributes setObject: @"Log In" forKey: @"buttonSubmit"];
	
	return [browser linkToSubmitFormNamed: @"AUTO" entries: authenticationAttributes];
}

@end