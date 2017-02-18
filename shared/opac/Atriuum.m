// =============================================================================
//
// Atriuum by BookSystems.
//
//		* Based on Rainbow City Public Library.
//		* My Account link not implmented.
//
// Main Account Page
// curl -b cookies.txt -o 'main.html' 'http://catalog.rbclibrary.org:7000/opac/rcpl/PatronCircInfo?mode=main&action=OPAC'
//
// Printer Formatted Page
// curl -b cookies.txt -o 'print.html' 'http://catalog.rbclibrary.org:7000/opac/rcpl/PatronCircInfo?action=OPAC&pagename=PrintPatronCirc.html'
//
// =============================================================================

#import "Atriuum.h"

@implementation Atriuum

- (BOOL) update
{
	URL *url = [catalogueURL URLWithPath: @"ProcessHttpReq"];
	url.rawAttributes = [NSString stringWithFormat: @"<actionmessagelist><action><type>patron_login</type><isOPAC>true</isOPAC><patronBarcode>%@</patronBarcode><pin>%@</pin></action></actionmessagelist>\n",
		[self.authenticationAttributes objectForKey: @"patronBarcode"],
		[self.authenticationAttributes objectForKey: @"pin"]
	];
	
	[browser go: url];
	[self authenticationOK];
	
	[browser go: [catalogueURL URLWithPath: @"PatronCircInfo?mode=main&action=OPAC"]];
//	[browser go: [Test fileURLFor: @"Atriuum/20111228_rainbow_loans.html"]];
//	[browser go: [Test fileURLFor: @"Atriuum/20131208_rainbow_loans.html"]];
	
	[self parseLoans1];
	if (loansCount == 0) [self parseLoans2];
	
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
	
	[scanner scanPassElementWithName: @"h3" attributeKey: @"id" attributeValue: @"itemscheckedout"];
	[scanner scanPassElementWithName: @"input" attributeKey: @"name" attributeValue: @"renewButton"];

	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a id=\"titleLink.*?>(.*?)</a>",		@"title",
		@"<td .*?>Author: (.*?)</td>",			@"author",
		@"<td .*?>Due On: (.*?)</td>",			@"dueDate",
		@"<td .*?>Times renewed: (.*?)</td>",	@"timesRenewed",	
		nil
	];

	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSDictionary *row = [element.scanner dictionaryUsingRegexMapping: mapping];
		[rows addObject: row];
	}
	
	[self addLoans: rows];
}

// -----------------------------------------------------------------------------
//
// Loans format 2.
//
// -----------------------------------------------------------------------------
- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	[scanner scanPassElementWithName: @"h3" attributeKey: @"id" attributeValue: @"itemscheckedout"];
	[scanner scanPassElementWithName: @"input" attributeKey: @"name" attributeValue: @"renewButton"];

	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a id=\"titleLink.*?>(.*?)</a>",		@"title",
		@"<br />Author: (.*?)\n",				@"author",
		@"<td.*?>Due On: (.*?)</td>",			@"dueDate",
		@"<td.*?>Times renewed: (.*?)</td>",	@"timesRenewed",
		nil
	];

	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSDictionary *row = [element.scanner dictionaryUsingRegexMapping: mapping];
		[rows addObject: row];
	}
	
	[self addLoans: rows];
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
	
	scanner = [scanner scannerForElementWithName: @"table" attributeKey: @"id" attributeRegex: @"reserveResultsTable"];
	if (scanner == nil) return;

	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<a id=\"reserveItem.*?>(.*?)</a>",	@"title",
		@"<td>Author: (.*?)</td>",				@"author",
		@"<td>(You are .*?)</td>",				@"queueDescription",	
		nil
	];

	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSDictionary *row = [element.scanner dictionaryUsingRegexMapping: mapping];
		[rows addObject: row];
	}
	
	[self addHolds: rows];
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
//		* Disabled because it doesn't auto log in.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	URL *url = [myAccountCatalogueURL URLWithPath: @"ProcessHttpReq"];
	url.rawAttributes = [NSString stringWithFormat: @"<actionmessagelist><action><type>patron_login</type><isOPAC>true</isOPAC><patronBarcode>%@</patronBarcode><pin>%@</pin></action></actionmessagelist>\n",
		[self.authenticationAttributes objectForKey: @"patronBarcode"],
		[self.authenticationAttributes objectForKey: @"pin"]
	];
	url.nextURL = [myAccountCatalogueURL URLWithPath: @"#url:PatronCircInfo?action=OPAC&mode=main"];
	
	return url;
}

@end