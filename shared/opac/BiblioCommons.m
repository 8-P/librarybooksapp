// =============================================================================
//
// BiblioCommons
//
//		* Screen scrap version.
//		* Implementation based on YPRL.
//
// =============================================================================

#import "BiblioCommons.h"

@implementation BiblioCommons

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/"]];
	if ([browser clickLink: @"Log Out"])
	{
		[Debug logError: @"Logged out"];
		[browser go: [catalogueURL URLWithPath: @"/"]];
	}
	[browser go: [catalogueURL URLWithPath: @"/user/login"]];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to find log in form"];
		return NO;
	}
	[self authenticationOK];
	
	[browser go: [browser.currentURL URLWithPath: @"/info/switch_language?selected_language=en-US"]];
	
	// Bibliocommons can someones refuse to log you in.  So abort if the log in
	// failed to avoid overwrite a good loans and holds list
	if ([browser.scanner scanPassString: @"LOGGED IN AS"] == NO)
	{
		[Debug logError: @"Failed to log in"];
		return NO;
	}
	
	URL *loansURL = [browser.currentURL URLWithPath: @"/checkedout"];
	URL *holdsURL = [browser.currentURL URLWithPath: @"/holds/index/active"];
	
//	loansURL = [Test fileURLFor: @"BiblioCommons/20101121_yprl_loans.html"];
//	loansURL = [Test fileURLFor: @"BiblioCommons/20101128_ottawa_loans.html"];
//	loansURL = [Test fileURLFor: @"BiblioCommons/20101229_ottawa_loans_overdue.html"];
//	loansURL = [Test fileURLFor: @"BiblioCommons/20131208_santaclara.html"];
	[browser go: loansURL];
	[self parseLoans1Page: 1];
	
//	oldsURL = [Test fileURLFor: @"BiblioCommons/20101119_yprl_holds.html"];
//	holdsURL = [Test fileURLFor: @"BiblioCommons/20110521_clevnet_holds.html"];
	[browser go: holdsURL];
	[self parseHolds1Page: 1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1Page: (NSInteger) page
{
	[Debug log: @"Parsing loans (page [%d], format 1)", page];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	scanner = [scanner scannerForElementWithName: @"div" attributeKey: @"id" attributeRegex: @"bibList"];
	if (scanner == nil) return;
	
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<span.*?class=\".*?title.*?\".*?>(.*?)</span>",					@"title",
		@"<span.*?class=\".*?title_extension.*?\".*?>(.*?)</span>",			@"titleExtension",
		@"<span.*?class=\".*?author.*?\".*?>(?:By )?(.*?)</span>",			@"author",
		@"<span.*?class=\".*?(?:coming_due|overdue).*?\".*?>(.*?)</span>",	@"dueDate",
		@"<span class=\"label\">Renewed:</span>.*?<span.*?>(.*?)</span>",	@"timesRenewed",
		nil
	];
	
	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeRegex: @"listItem" intoElement: &element])
	{
		NSDictionary *row = [element.scanner dictionaryUsingRegexMapping: mapping];
		[rows addObject: row];
	}

	[self addLoans: rows];
	
	// Look for the next page link
	scanner = browser.scanner;
	[scanner scanPassHead];
	if (page < 100
		&& ([scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"pageButtons" intoElement: &element recursive: YES]
			|| [scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"pagination" intoElement: &element recursive: YES]))
	{
		NSString *href = [element.scanner linkForLabel: @"Next"];
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
- (void) parseHolds1Page: (NSInteger) page;
{
	[Debug log: @"Parsing holds (page [%d], format 1)", page];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	scanner = [scanner scannerForElementWithName: @"div" attributeKey: @"id" attributeRegex: @"bibList"];
	if (scanner == nil) return;

	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<span.*?class=\".*?title.*?\".*?>(.*?)</span>",	@"title",
		@"Position:</span>.*?<span.*?>(.*?)</span>",		@"queuePosition",
		@"Location:</span>.*?<span.*?>(.*?)</span>",		@"pickupAt",
		@"Status:</span>.*?<span.*?>(.*?)</span>",			@"queueDescription",
		@"Pick Up by:</span>.*?<span.*?>(.*?)</span>",		@"expiryDate",	
		nil
	];

	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeRegex: @"listItem" intoElement: &element])
	{
		NSDictionary *row = [element.scanner dictionaryUsingRegexMapping: mapping];
		[rows addObject: row];
	}

	[self addHolds: rows];
	
	// Look for the next page link
	scanner = browser.scanner;
	[scanner scanPassHead];
	if (page < 100
		&& ([scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"pageButtons" intoElement: &element recursive: YES]
			|| [scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"pagination" intoElement: &element recursive: YES]))
	{
		NSString *href = [element.scanner linkForLabel: @"Next"];
		if (href)
		{
			[Debug log: @"Found next page link [%@]", href];
			[browser go: [browser.currentURL URLWithPath: href]];
			[self parseHolds1Page: page + 1];
		}
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: [myAccountCatalogueURL URLWithPath: @"/"]];
	if ([browser clickLink: @"Log Out"])
	{
		[Debug logError: @"Logged out"];
		[browser go: [myAccountCatalogueURL URLWithPath: @"/"]];
	}
	[browser go: [myAccountCatalogueURL URLWithPath: @"/user/login"]];

	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end